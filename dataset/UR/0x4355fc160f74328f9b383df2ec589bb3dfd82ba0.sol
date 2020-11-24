 

pragma solidity ^0.4.8;


 
library SafeMath {
  function mul(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a * b;
    if(!(a == 0 || c / a == b)) throw;
    return c;
  }

  function div(uint256 a, uint256 b) internal returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function sub(uint256 a, uint256 b) internal returns (uint256) {
    if(!(b <= a)) throw;
    return a - b;
  }

  function add(uint256 a, uint256 b) internal returns (uint256) {
    uint256 c = a + b;
    if(!(c >= a)) throw;
    return c;
  }

  function max64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a >= b ? a : b;
  }

  function min64(uint64 a, uint64 b) internal constant returns (uint64) {
    return a < b ? a : b;
  }

  function max256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a >= b ? a : b;
  }

  function min256(uint256 a, uint256 b) internal constant returns (uint256) {
    return a < b ? a : b;
  }

}

contract ContractReceiver{
    function tokenFallback(address _from, uint256 _value, bytes  _data) external;
}


 
 
contract ERC23BasicToken {
    using SafeMath for uint256;
    uint256 public totalSupply;
    mapping(address => uint256) balances;
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    function tokenFallback(address _from, uint256 _value, bytes  _data) external {
        throw;
    }

    function transfer(address _to, uint256 _value, bytes _data) returns (bool success) {

         

        if(isContract(_to)) {
            transferToContract(_to, _value, _data);
        }
        else {
            transferToAddress(_to, _value, _data);
        }
        return true;
    }

    function transfer(address _to, uint256 _value) {

         
         

        bytes memory empty;
        if(isContract(_to)) {
            transferToContract(_to, _value, empty);
        }
        else {
            transferToAddress(_to, _value, empty);
        }
    }

    function transferToAddress(address _to, uint256 _value, bytes _data) internal {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
     }

    function transferToContract(address _to, uint256 _value, bytes _data) internal {
        balances[msg.sender] = balances[msg.sender].sub( _value);
        balances[_to] = balances[_to].add( _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        Transfer(msg.sender, _to, _value);    }

    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
    function isContract(address _addr) returns (bool is_contract) {
          uint256 length;
          assembly {
               
              length := extcodesize(_addr)
          }
          if(length>0) {
              return true;
          }
          else {
              return false;
          }
    }
}

contract ERC23StandardToken is ERC23BasicToken {
    mapping (address => mapping (address => uint256)) allowed;
    event Approval (address indexed owner, address indexed spender, uint256 value);

    function transferFrom(address _from, address _to, uint256 _value) {
        var _allowance = allowed[_from][msg.sender];

         
         

        balances[_to] = balances[_to].add(_value);
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = _allowance.sub(_value);
        Transfer(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) {

         
         
         
         
        if ((_value != 0) && (allowed[msg.sender][_spender] != 0)) throw;

        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
    }

    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

}




 
 
contract OpusToken is ERC23StandardToken {
    string public constant name = "Opus Token";
    string public constant symbol = "OPT";
    uint256 public constant decimals = 18;
    address public multisig=address(0x1426c1f91b923043F7C5FbabC6e369e7cBaef3f0);  
    address public foundation;  
    address public candidate;  

    mapping (address => uint256) contributions;  
    uint256 public startBlock = 4023333;  
    uint256 public preEndBlock = 4057233;  
    uint256 public phase1StartBlock = 4066633;  
    uint256 public phase1EndBlock = 4100233;  
    uint256 public phase2EndBlock = 4133833;  
    uint256 public phase3EndBlock = 4201433;  
    uint256 public endBlock = 4201433;  
    uint256 public crowdsaleTokenSupply = 900000000 * (10**18);  
    uint256 public ecosystemTokenSupply = 100000000 * (10**18);  
    uint256 public foundationTokenSupply = 600000000 * (10**18);  
    uint256 public crowdsaleTokenSold = 0;  
    uint256 public presaleEtherRaised = 0;  
    uint256 public transferLockup = 9600;
    bool public halted = false;  
    event Halt();  
    event Unhalt();  

    modifier onlyFoundation() {
         
        if (msg.sender != foundation) throw;
        _;
    }

    modifier crowdsaleTransferLock() {
         
        if (block.number <= endBlock.add(transferLockup)) throw;
        _;
    }

    modifier whenNotHalted() {
         
        if (halted) throw;
        _;
    }

     
     
  	function OpusToken() {
        foundation = msg.sender;
        totalSupply = ecosystemTokenSupply.add(foundationTokenSupply);
        balances[foundation] = totalSupply;
  	}

     
    function() payable {
        buy();
    }


     
    function halt() onlyFoundation {
        halted = true;
        Halt();
    }

    function unhalt() onlyFoundation {
        halted = false;
        Unhalt();
    }

    function buy() payable {
        buyRecipient(msg.sender);
    }

     
    function buyRecipient(address recipient) public payable whenNotHalted {
        if(msg.value == 0) throw;
        if(!(preCrowdsaleOn()||crowdsaleOn())) throw; 
        if(contributions[recipient].add(msg.value)>perAddressCap()) throw; 
        uint256 tokens = msg.value.mul(returnRate());  
        if(crowdsaleTokenSold.add(tokens)>crowdsaleTokenSupply) throw; 

        balances[recipient] = balances[recipient].add(tokens);
        totalSupply = totalSupply.add(tokens);
        presaleEtherRaised = presaleEtherRaised.add(msg.value);
        contributions[recipient] = contributions[recipient].add(msg.value);
        crowdsaleTokenSold = crowdsaleTokenSold.add(tokens);
        if(crowdsaleTokenSold == crowdsaleTokenSupply){
         
            if(block.number < preEndBlock) {
                preEndBlock = block.number;
            }
            endBlock = block.number;
        }
        if (!multisig.send(msg.value)) throw;  
        Transfer(this, recipient, tokens);
    }

     
     
    function burn(uint256 _value) external onlyFoundation returns (bool) {
        balances[msg.sender] = balances[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);
        Transfer(msg.sender, address(0), _value);
        return true;
    }

     
     
    function proposeFoundationTransfer(address newFoundation) external onlyFoundation {
         
        candidate = newFoundation;
    }

    function cancelFoundationTransfer() external onlyFoundation {
        candidate = address(0);
    }

    function acceptFoundationTransfer() external {
         
        if(msg.sender != candidate) throw;
        foundation = candidate;
        candidate = address(0);
    }

     
    function setMultisig(address addr) external onlyFoundation {
      	if (addr == address(0)) throw;
      	multisig = addr;
    }

    function transfer(address _to, uint256 _value, bytes _data) public crowdsaleTransferLock returns (bool success) {
        return super.transfer(_to, _value, _data);
    }

	  function transfer(address _to, uint256 _value) public crowdsaleTransferLock {
        super.transfer(_to, _value);
	  }

    function transferFrom(address _from, address _to, uint256 _value) public crowdsaleTransferLock {
        super.transferFrom(_from, _to, _value);
    }

     
    function returnRate() public constant returns(uint256) {
        if (block.number>=startBlock && block.number<=preEndBlock) return 8888;  
        if (block.number>=phase1StartBlock && block.number<=phase1EndBlock) return 8000;  
        if (block.number>phase1EndBlock && block.number<=phase2EndBlock) return 7500;  
        if (block.number>phase2EndBlock && block.number<=phase3EndBlock) return 7000;  
    }

     
    function perAddressCap() public constant returns(uint256) {
        uint256 baseline = 1000 * (10**18);
        return baseline.add(presaleEtherRaised.div(100));
    }

    function preCrowdsaleOn() public constant returns (bool) {
         
        return (block.number>=startBlock && block.number<=preEndBlock);
    }

    function crowdsaleOn() public constant returns (bool) {
         
        return (block.number>=phase1StartBlock && block.number<=endBlock);
    }


    function getEtherRaised() external constant returns (uint256) {
         
        return presaleEtherRaised;
    }

    function getTokenSold() external constant returns (uint256) {
         
        return crowdsaleTokenSold;
    }

}
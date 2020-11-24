 

pragma solidity ^0.4.11;

     
     
     
     
     
     
    

      
      
     
library SafeMath {

     
     
     
    function add(uint a, uint b) internal returns (uint) {
        uint c = a + b;
        assert(c >= a && c >= b);
        return c;
    }

     
     
     
    function sub(uint a, uint b) internal returns (uint) {
        assert(b <= a);
        return a - b;
    }
}


 
 
 
contract Owned {
    address public owner;
    address public newOwner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address _newOwner) onlyOwner {
        newOwner = _newOwner;
    }
 
    function acceptOwnership() {
        if (msg.sender == newOwner) {
            OwnershipTransferred(owner, newOwner);
            owner = newOwner;
        }
    }
}


 
 
 
 
contract ERC20Token is Owned {
    using SafeMath for uint;

     
     
     
    uint256 _totalSupply = 100000000.000000000000000000;

     
     
     
    mapping(address => uint256) balances;

     
     
     
    mapping(address => mapping (address => uint256)) allowed;

     
     
     
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = _totalSupply;
    }

     
     
     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        return balances[_owner];
    }

     
     
     
    function transfer(address _to, uint256 _amount) returns (bool success) {
        if (balances[msg.sender] >= _amount                 
            && _amount > 0                                  
            && balances[_to] + _amount > balances[_to]      
        ) {
            balances[msg.sender] = balances[msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(msg.sender, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
     
    function approve(
        address _spender,
        uint256 _amount
    ) returns (bool success) {
        allowed[msg.sender][_spender] = _amount;
        Approval(msg.sender, _spender, _amount);
        return true;
    }

     
     
     
     
     
    function transferFrom(
        address _from,
        address _to,
        uint256 _amount
    ) returns (bool success) {
        if (balances[_from] >= _amount                   
            && allowed[_from][msg.sender] >= _amount     
            && _amount > 0                               
            && balances[_to] + _amount > balances[_to]   
        ) {
            balances[_from] = balances[_from].sub(_amount);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
            balances[_to] = balances[_to].add(_amount);
            Transfer(_from, _to, _amount);
            return true;
        } else {
            return false;
        }
    }

     
     
     
     
    function allowance(
        address _owner, 
        address _spender
    ) constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender,
        uint256 _value);
}


contract IntegrativeWalletToken is ERC20Token {

     
     
     
    string public constant symbol = "IWT";
    string public constant name = "Integrative Wallet Token";
    uint256 public constant decimals = 18;
    uint256 public constant IWTfund = 55 * (10**6) * 10**decimals;    

     
    uint256 public constant STARTDATE = 1504184400;
    uint256 public constant ENDDATE = STARTDATE + 28 days;

     
    uint256 public constant CAP = 63500 ether;

     
    address public multisig = 0xf82D89f274e2C5FE9FD3202C5426ABE47D2099Cd;
    address public iwtfundtokens = 0x1E408cE343F4a392B430dFC5E3e2fE3B6a9Cc580;


    uint256 public totalEthers;

    function IntegrativeWalletToken() {
		
	  balances[iwtfundtokens] = IWTfund;    

    }

  
     
     
     
     
     
     
     
	
    function buyPrice() constant returns (uint256) {
        return buyPriceAt(now);
    }

    function buyPriceAt(uint256 at) constant returns (uint256) {
        if (at < STARTDATE) {
            return 0;
        } else if (at < (STARTDATE + 1 days)) {
            return 1200;
        } else if (at < (STARTDATE + 8 days)) {
            return 1000;
        } else if (at < (STARTDATE + 15 days)) {
            return 800;
        } else if (at < (STARTDATE + 22 days)) {
            return 600;
        } else if (at <= ENDDATE) {
            return 600;
        } else {
            return 0;
        }
    }


     
     
     
    function () payable {
        proxyPayment(msg.sender);
    }

    function proxyPayment(address participant) payable {
         
        require(now >= STARTDATE);
         
        require(now <= ENDDATE);
         
        require(msg.value > 0);

         
        totalEthers = totalEthers.add(msg.value);
         
        require(totalEthers <= CAP);

         
        uint256 _buyPrice = buyPrice();

         
         
        uint tokens = msg.value * _buyPrice;

         
        require(tokens > 0);
   

         
        balances[participant] = balances[participant].add(tokens);

         
        TokensBought(participant, msg.value, totalEthers, tokens, _totalSupply, _buyPrice);
        Transfer(0x0, participant, tokens);

         
        multisig.transfer(msg.value);
    }
    event TokensBought(address indexed buyer, uint256 ethers, 
        uint256 newEtherBalance, uint256 tokens, 
        uint256 newTotalSupply, uint256 buyPrice);


    function addPrecommitment(address participant, uint balance) onlyOwner {
        require(now < STARTDATE);
        require(balance > 0);
        balances[participant] = balances[participant].add(balance);
        _totalSupply = _totalSupply.add(balance);
        Transfer(0x0, participant, balance);
    }


    function transfer(address _to, uint _amount) returns (bool success) {
         
        require(now > ENDDATE || totalEthers == CAP);
         
        return super.transfer(_to, _amount);
    }

    function transferFrom(address _from, address _to, uint _amount) 
        returns (bool success)
    {
         
        require(now > ENDDATE || totalEthers == CAP);
         
        return super.transferFrom(_from, _to, _amount);
    }


    function transferAnyERC20Token(address tokenAddress, uint amount)
      onlyOwner returns (bool success) 
    {
        return ERC20Token(tokenAddress).transfer(owner, amount);
    }
    
     
     
     
     
     
     
    
    
}
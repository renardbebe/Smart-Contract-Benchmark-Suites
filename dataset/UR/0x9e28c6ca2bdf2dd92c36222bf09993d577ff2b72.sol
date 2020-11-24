 

pragma solidity ^0.4.18;

 
contract SafeMath {
  function safeMul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function safeDiv(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function safeSub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function safeAdd(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}
 
contract Ownable {
  address public owner;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  function Ownable() public {
    owner = msg.sender;
  }


   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }


   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }

}
 
 
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address _who) public constant returns (uint);
  function allowance(address _owner, address _spender) public constant returns (uint);

  function transfer(address _to, uint _value) public returns (bool ok);
  function transferFrom(address _from, address _to, uint _value) public returns (bool ok);
  function approve(address _spender, uint _value) public returns (bool ok);
  event Transfer(address indexed from, address indexed to, uint value);
  event Approval(address indexed owner, address indexed spender, uint value);
}
contract Haltable is Ownable {

     
    bool public halted = false;
     
    function Haltable() public {}

     
    modifier stopIfHalted {
      require(!halted);
      _;
    }

     
    modifier runIfHalted{
      require(halted);
      _;
    }

     
    function halt() onlyOwner stopIfHalted public {
        halted = true;
    }
     
    function unHalt() onlyOwner runIfHalted public {
        halted = false;
    }
}

contract iCapToken is ERC20,SafeMath,Haltable {

     
    bool public isiCapToken = false;

     
    uint256 public start;
     
    uint256 public end;
     
    uint256 public maxTokenSupply = 500000000 ether;
     
    uint256 public perEtherTokens = 208;
     
    address public multisig;
     
    address public unspentWalletAddress;
     
    bool public isFinalized = false;

     
    string public constant name = "integratedCAPITAL";
    string public constant symbol = "iCAP";
    uint256 public constant decimals = 18;  

     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowed;
     
    mapping (address => mapping (address => uint256)) allowedToBurn;

    event Mint(address indexed to, uint256 amount);
    event Burn(address owner,uint256 _value);
    event ApproveBurner(address owner, address canBurn, uint256 value);
    event BurnFrom(address _from,uint256 _value);
    
    function iCapToken(uint256 _start,uint256 _end) public {
        totalSupply = 500000000 ether;
        balances[msg.sender] = totalSupply;
        start = safeAdd(now, _start);
        end = safeAdd(now, _end);
        isiCapToken = true;
        emit Transfer(address(0), msg.sender,totalSupply);
    }

     
     
    function setFundingStartTime(uint256 _start) public stopIfHalted onlyOwner {
        start = now + _start;
    }

     
     
    function setFundingEndTime(uint256 _end) public stopIfHalted onlyOwner {
        end = now + _end;
    }

     
     
    function setPerEtherTokens(uint256 _perEtherTokens) public onlyOwner {
        perEtherTokens = _perEtherTokens;
    }

     
     
    function setMultisigWallet(address _multisig) onlyOwner public {
        require(_multisig != 0);
        multisig = _multisig;
    }

     
     
    function setUnspentWalletAddress(address _unspentWalletAddress) onlyOwner public {
        require(_unspentWalletAddress != 0);
        unspentWalletAddress = _unspentWalletAddress;
    }

     
    function() payable stopIfHalted public {
         
        require(now >= start && now <= end);
         
        require(msg.value > 0);
         
        require(unspentWalletAddress != address(0));

         
        uint256 calculatedTokens = safeMul(msg.value, perEtherTokens);

         
        require(calculatedTokens < balances[unspentWalletAddress]);

         
        assignTokens(msg.sender, calculatedTokens);
    }

     
     
    function assignTokens(address investor, uint256 tokens) internal {
         
        balances[unspentWalletAddress] = safeSub(balances[unspentWalletAddress], tokens);

         
        balances[investor] = safeAdd(balances[investor], tokens);

         
        Transfer(unspentWalletAddress, investor, tokens);
    }

     
    function finalize() onlyOwner public {
         
        require(now > end);
         
        require(!isFinalized && multisig != address(0));
         
        isFinalized = true;
        require(multisig.send(address(this).balance));
    }

     
     
    function balanceOf(address _who) public constant returns (uint) {
        return balances[_who];
    }

     
     
     
    function allowance(address _owner, address _spender) public constant returns (uint) {
        return allowed[_owner][_spender];
    }

     
     
     
    function allowanceToBurn(address _owner, address _spender) public constant returns (uint) {
        return allowedToBurn[_owner][_spender];
    }

     
     
     
     
     
    function transfer(address _to, uint _value) public returns (bool ok) {
         
        require(_to != 0 && _value > 0);
        uint256 senderBalance = balances[msg.sender];
         
        require(senderBalance >= _value);
        senderBalance = safeSub(senderBalance, _value);
        balances[msg.sender] = senderBalance;
        balances[_to] = safeAdd(balances[_to],_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
     
     
     
    function transferFrom(address _from, address _to, uint _value) public returns (bool ok) {
         
        require(_from != 0 && _to != 0 && _value > 0);
         
        require(allowed[_from][msg.sender] >= _value && balances[_from] >= _value);
        balances[_from] = safeSub(balances[_from],_value);
        balances[_to] = safeAdd(balances[_to],_value);
        allowed[_from][msg.sender] = safeSub(allowed[_from][msg.sender],_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
     
     
     
    function approve(address _spender, uint _value) public returns (bool ok) {
         
        require(_spender != 0);
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
     
     
     
     
    function mint(address _account, uint256 _amount) public onlyOwner stopIfHalted returns (bool ok) {
        require(_account != 0);
        totalSupply = safeAdd(totalSupply,_amount);
        balances[_account] = safeAdd(balances[_account],_amount);
        emit Mint(_account, _amount);
        emit Transfer(address(0), _account, _amount);
        return true;
    }

     
     
     
     
    function approveForBurn(address _canBurn, uint _value) public returns (bool ok) {
         
        require(_canBurn != 0);
        allowedToBurn[msg.sender][_canBurn] = _value;
        ApproveBurner(msg.sender, _canBurn, _value);
        return true;
    }

     
     
     
     
    function burn(uint _value) public returns (bool ok) {
         
        require(_value > 0);
        uint256 senderBalance = balances[msg.sender];
        require(senderBalance >= _value);
        senderBalance = safeSub(senderBalance, _value);
        balances[msg.sender] = senderBalance;
        totalSupply = safeSub(totalSupply,_value);
        Burn(msg.sender, _value);
        return true;
    }

     
     
     
     
     
     
    function burnFrom(address _from, uint _value) public returns (bool ok) {
         
        require(_from != 0 && _value > 0);
         
        require(allowedToBurn[_from][msg.sender] >= _value && balances[_from] >= _value);
        balances[_from] = safeSub(balances[_from],_value);
        totalSupply = safeSub(totalSupply,_value);
        allowedToBurn[_from][msg.sender] = safeSub(allowedToBurn[_from][msg.sender],_value);
        BurnFrom(_from, _value);
        return true;
    }
}
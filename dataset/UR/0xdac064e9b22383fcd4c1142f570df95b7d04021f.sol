 

pragma solidity ^0.5.1;

contract tokenRecipientInterface {
  function receiveApproval(address _from, uint256 _value, address _token, bytes memory _extraData) public;
}

contract ERC20TokenInterface {
  function totalSupply() public view returns (uint256 _totalSupply);
  function balanceOf(address _owner) public view returns (uint256 balance);
  function transfer(address _to, uint256 _value) public returns (bool success);
  function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
  function approve(address _spender, uint256 _value) public returns (bool success);
  function allowance(address _owner, address _spender) public view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

contract SafeMath {
    
    uint256 constant public MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function safeAdd(uint256 x, uint256 y) pure internal returns (uint256 z) {
        require(x <= MAX_UINT256 - y);
        return x + y;
    }

    function safeSub(uint256 x, uint256 y) pure internal returns (uint256 z) {
        require(x >= y);
        return x - y;
    }

    function safeMul(uint256 x, uint256 y) pure internal returns (uint256 z) {
        if (y == 0) {
            return 0;
        }
        require(x <= (MAX_UINT256 / y));
        return x * y;
    }
}

contract Owned {
    address payable public owner;
    address payable public newOwner;

    constructor() public{
         
    }

    modifier onlyOwner {
        assert(msg.sender == owner);
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = address(0x0);
    }

    event OwnerUpdate(address _prevOwner, address _newOwner);
}

contract Lockable is Owned {

    uint256 public lockedUntilBlock;

    event ContractLocked(uint256 _untilBlock, string _reason);

    modifier lockAffected {
        require(block.number > lockedUntilBlock);
        _;
    }

    function lockFromSelf(uint256 _untilBlock, string memory _reason) internal {
        lockedUntilBlock = _untilBlock;
        emit ContractLocked(_untilBlock, _reason);
    }


    function lockUntil(uint256 _untilBlock, string memory _reason) onlyOwner public {
        lockedUntilBlock = _untilBlock;
        emit ContractLocked(_untilBlock, _reason);
    }
}

contract ERC20Token is ERC20TokenInterface, SafeMath, Owned, Lockable {

     
    string public name;
     
    string public symbol;
     
    uint8 public decimals;
     
    uint256 public totalSupplyLimit;

     
    uint256 supply = 0;
     
    mapping (address => uint256) balances;
     
    mapping (address => mapping (address => uint256)) allowances;

     
    event Mint(address indexed _to, uint256 _value);
     
    event Burn(address indexed _from, uint _value);

     
    function totalSupply() public view returns (uint256) {
        return supply;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) lockAffected public returns (bool success) {
        require(_to != address(0x0) && _to != address(this));
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) lockAffected public returns (bool success) {
        allowances[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function approveAndCall(address _spender, uint256 _value, bytes memory _extraData) lockAffected public returns (bool success) {
        tokenRecipientInterface spender = tokenRecipientInterface(_spender);
        approve(_spender, _value);
        spender.receiveApproval(msg.sender, _value, address(this), _extraData);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) lockAffected public returns (bool success) {
        require(_to != address(0x0) && _to != address(this));
        balances[_from] = safeSub(balanceOf(_from), _value);
        balances[_to] = safeAdd(balanceOf(_to), _value);
        allowances[_from][msg.sender] = safeSub(allowances[_from][msg.sender], _value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowances[_owner][_spender];
    }

     
    function mintTokens(address _to, uint256 _amount) onlyOwner public {
        require(supply + _amount <= totalSupplyLimit);
        supply = safeAdd(supply, _amount);
        balances[_to] = safeAdd(balances[_to], _amount);
        emit Mint(_to, _amount);
        emit Transfer(address(0x0), _to, _amount);
    }

     
    function burn(uint _amount) public {
        balances[msg.sender] = safeSub(balanceOf(msg.sender), _amount);
        supply = safeSub(supply, _amount);
        emit Burn(msg.sender, _amount);
        emit Transfer(msg.sender, address(0x0), _amount);
    }

     
    function salvageTokensFromContract(address _tokenAddress, address _to, uint _amount) onlyOwner public {
        ERC20TokenInterface(_tokenAddress).transfer(_to, _amount);
    }

     
    function killContract() public onlyOwner {
        selfdestruct(owner);
    }
}

contract MRPROTokenContract is ERC20Token {

     
    constructor() public {
        owner = 0xa12F88dC40BA5629C87D37d20EE46759b6a2f6ac;
        name = "MRPROToken";
        symbol = "MRPRO";
        decimals = 18;
        totalSupplyLimit = 1000000000 * 10**18;
    }
}
 

pragma solidity ^0.5.0;

interface Token {
   
  function totalSupply() external view returns (uint256 supply);

   
   
  function balanceOf(address _owner) external view returns (uint256 balance);

   
   
   
   
  function transfer(address _to, uint256 _value) external returns (bool success);

   
   
   
   
   
  function transferFrom(address _from, address _to, uint256 _value) external returns (bool success);

   
   
   
   
  function approve(address _spender, uint256 _value) external returns (bool success);

   
   
   
  function allowance(address _owner, address _spender) external view returns (uint256 remaining);

  event Transfer(address indexed _from, address indexed _to, uint256 _value);
  event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

library SafeMath {
    function safeMul(uint a, uint b) internal pure returns (uint) {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function safeSub(uint a, uint b) internal pure returns (uint) {
        assert(b <= a);
        return a - b;
    }

    function safeAdd(uint a, uint b) internal pure returns (uint) {
        uint c = a + b;
        assert(c>=a && c>=b);
        return c;
    }

    function safeDiv(uint a, uint b) internal pure returns (uint) {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }
}

contract ERC20 is Token {
    using SafeMath for uint256;
    
    mapping (address => uint256) public balance;

    mapping (address => mapping (address => uint256)) public allowed;

    event Transfer(address indexed from, address indexed to, uint256 value);

    event TransferFrom(address indexed spender, address indexed from, address indexed to, uint256 _value);

    event Approval(address indexed owner, address indexed spender, uint256 value);

    uint256 constant private MAX_UINT256 = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Can't send to null");

        balance[msg.sender] = balance[msg.sender].safeSub(_value);
        balance[_to] = balance[_to].safeAdd(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_to != address(0), "Can't send to null");
        require(_to != address(this), "Can't send to contract");
        
        uint256 allowance = allowed[_from][msg.sender];
        require(_value <= allowance || _from == msg.sender, "Not allowed to send that much");

        balance[_to] = balance[_to].safeAdd(_value);
        balance[_from] = balance[_from].safeSub(_value);

        if (allowed[_from][msg.sender] != MAX_UINT256 && _from != msg.sender) {
            allowed[_from][msg.sender] = allowed[_from][msg.sender].safeSub(_value);
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(_spender != address(0), "spender can't be null");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        remaining = allowed[_owner][_spender];
    } 

    function totalSupply() public view returns (uint256 supply) {
        return 0;
    }

    function balanceOf(address _owner) public view returns (uint256 ownerBalance) {
        return balance[_owner];
    }
}

contract Ownable {
    address payable public admin;

   
    constructor() public {
        admin = msg.sender;
    }

   
    modifier onlyAdmin() {
        require(msg.sender == admin, "Function reserved to admin");
        _;
    }

   

    function transferOwnership(address payable _newAdmin) public onlyAdmin {
        require(_newAdmin != address(0), "New admin can't be null");
        admin = _newAdmin;
    }

    function destroy() public onlyAdmin {
        selfdestruct(admin);
    }

    function destroyAndSend(address payable _recipient) public onlyAdmin {
        selfdestruct(_recipient);
    }
}

contract NotTransferable is ERC20, Ownable {
     
    
    bool public enabledTransfer = false;

    function enableTransfers(bool _enabledTransfer) public onlyAdmin {
        enabledTransfer = _enabledTransfer;
    }

    function transferFromContract(address _to, uint256 _value) public onlyAdmin returns (bool success) {
        return super.transfer(_to, _value);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        require(enabledTransfer, "Transfers are not allowed yet");
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(enabledTransfer, "Transfers are not allowed yet");
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public returns (bool) {
        require(enabledTransfer, "Transfers are not allowed yet");
        return super.approve(_spender, _value);
    }
}

contract Coinstantine is NotTransferable {

    string constant public NAME = "Coinstantine";

    string constant public SYMBOL = "CSN";

    uint8 constant public DECIMALS = 18;

    uint256 public TOTALSUPPLY = 10 ** (8 + 18);  

    constructor() public {
        enabledTransfer = true;
        balance[msg.sender] = TOTALSUPPLY;
    }

    function totalSupply() public view returns (uint256 supply) {
        return TOTALSUPPLY;
    }
}
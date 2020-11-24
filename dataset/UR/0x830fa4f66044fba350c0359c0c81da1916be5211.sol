 

pragma solidity ^0.4.19;

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
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

contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ACAToken is ERC20 {
    using SafeMath for uint256;

    address public owner;
    address public admin;
    address public saleAddress;

    string public name = "ACA Network Token";
    string public symbol = "ACA";
    uint8 public decimals = 18;

    uint256 totalSupply_;
    mapping (address => mapping (address => uint256)) internal allowed;
    mapping (address => uint256) balances;

    bool transferable = false;
    mapping (address => bool) internal transferLocked;

    event Genesis(address owner, uint256 value);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event AdminTransferred(address indexed previousAdmin, address indexed newAdmin);
    event Burn(address indexed burner, uint256 value);
    event LogAddress(address indexed addr);
    event LogUint256(uint256 value);
    event TransferLock(address indexed target, bool value);

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier onlyAdmin() {
        require(msg.sender == owner || msg.sender == admin);
        _;
    }

    modifier canTransfer(address _from, address _to) {
        require(_to != address(0x0));
        require(_to != address(this));

        if ( _from != owner && _from != admin ) {
            require(transferable);
            require (!transferLocked[_from]);
        }
        _;
    }

     
    function ACAToken(uint256 _totalSupply, address _saleAddress, address _admin) public {
        require(_totalSupply > 0);
        owner = msg.sender;
        require(_saleAddress != address(0x0));
        require(_saleAddress != address(this));
        require(_saleAddress != owner);

        require(_admin != address(0x0));
        require(_admin != address(this));
        require(_admin != owner);

        require(_admin != _saleAddress);

        admin = _admin;
        saleAddress = _saleAddress;

        totalSupply_ = _totalSupply;

        balances[owner] = totalSupply_;
        approve(saleAddress, totalSupply_);

        emit Genesis(owner, totalSupply_);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        require(newOwner != address(this));
        require(newOwner != admin);

        owner = newOwner;
        emit OwnershipTransferred(owner, newOwner);
    }

    function transferAdmin(address _newAdmin) public onlyOwner {
        require(_newAdmin != address(0));
        require(_newAdmin != address(this));
        require(_newAdmin != owner);

        admin = _newAdmin;
        emit AdminTransferred(admin, _newAdmin);
    }

    function setTransferable(bool _transferable) public onlyAdmin {
        transferable = _transferable;
    }

    function isTransferable() public view returns (bool) {
        return transferable;
    }

    function transferLock() public returns (bool) {
        transferLocked[msg.sender] = true;
        emit TransferLock(msg.sender, true);
        return true;
    }

    function manageTransferLock(address _target, bool _value) public onlyAdmin returns (bool) {
        transferLocked[_target] = _value;
        emit TransferLock(_target, _value);
        return true;
    }

    function transferAllowed(address _target) public view returns (bool) {
        return (transferable && transferLocked[_target] == false);
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

    function transfer(address _to, uint256 _value) canTransfer(msg.sender, _to) public returns (bool) {
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

    function balanceOfOwner() public view returns (uint256 balance) {
        return balances[owner];
    }

    function transferFrom(address _from, address _to, uint256 _value) public canTransfer(_from, _to) returns (bool) {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public canTransfer(msg.sender, _spender) returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

    function increaseApproval(address _spender, uint _addedValue) public canTransfer(msg.sender, _spender) returns (bool) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public canTransfer(msg.sender, _spender) returns (bool) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function burn(uint256 _value) public {
        require(_value <= balances[msg.sender]);
         
         

        address burner = msg.sender;
        balances[burner] = balances[burner].sub(_value);
        totalSupply_ = totalSupply_.sub(_value);
        emit Burn(burner, _value);
    }

    function emergencyERC20Drain(ERC20 _token, uint256 _amount) public onlyOwner {
        _token.transfer(owner, _amount);
    }
}
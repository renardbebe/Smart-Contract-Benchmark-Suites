 

pragma solidity ^0.4.22;


 
contract Ownable {
  address public owner;
  address delegate;


  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


   
  constructor() public {
    owner = msg.sender;
    emit OwnershipTransferred(address(0), owner);
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

   
  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    delegate = newOwner;
  }

  function confirmChangeOwnership() public {
    require(msg.sender == delegate);
    emit OwnershipTransferred(owner, delegate);
    owner = delegate;
    delegate = 0;
  }

}







 
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







contract TransferFilter is Ownable {
  bool public isTransferable;
  mapping( address => bool ) public mapAddressPass;
  mapping( address => bool ) public mapAddressBlock;

  event LogFilterPass(address indexed target, bool status);
  event LogFilterBlock(address indexed target, bool status);

   
  modifier checkTokenTransfer(address source) {
      if (isTransferable == true) {
          require(mapAddressBlock[source] == false);
      }
      else {
          require(mapAddressPass[source] == true);
      }
      _;
  }

  constructor() public {
      isTransferable = true;
  }

  function setTransferable(bool status) public onlyOwner {
      isTransferable = status;
  }

  function isInPassFilter(address user) public view returns (bool) {
    return mapAddressPass[user];
  }

  function isInBlockFilter(address user) public view returns (bool) {
    return mapAddressBlock[user];
  }

  function addressToPass(address[] target, bool status)
  public
  onlyOwner
  {
    for( uint i = 0 ; i < target.length ; i++ ) {
        address targetAddress = target[i];
        bool old = mapAddressPass[targetAddress];
        if (old != status) {
            if (status == true) {
                mapAddressPass[targetAddress] = true;
                emit LogFilterPass(targetAddress, true);
            }
            else {
                delete mapAddressPass[targetAddress];
                emit LogFilterPass(targetAddress, false);
            }
        }
    }
  }

  function addressToBlock(address[] target, bool status)
  public
  onlyOwner
  {
      for( uint i = 0 ; i < target.length ; i++ ) {
          address targetAddress = target[i];
          bool old = mapAddressBlock[targetAddress];
          if (old != status) {
              if (status == true) {
                  mapAddressBlock[targetAddress] = true;
                  emit LogFilterBlock(targetAddress, true);
              }
              else {
                  delete mapAddressBlock[targetAddress];
                  emit LogFilterBlock(targetAddress, false);
              }
          }
      }
  }
}


 
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
contract StandardToken is ERC20, TransferFilter {
  using SafeMath for uint256;

  mapping(address => uint256) balances;

  mapping (address => mapping (address => uint256)) internal allowed;

  modifier onlyPayloadSize(uint size) {
    require(msg.data.length >= size + 4);
    _;
  }

   
  function transfer(address _to, uint256 _value)
  onlyPayloadSize(2 * 32)
  checkTokenTransfer(msg.sender)
  public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[msg.sender]);

     
    balances[msg.sender] = balances[msg.sender].sub(_value);
    balances[_to] = balances[_to].add(_value);
    emit Transfer(msg.sender, _to, _value);
    return true;
  }

   
  function balanceOf(address _owner) public view returns (uint256 balance) {
    return balances[_owner];
  }

   
  function transferFrom(address _from, address _to, uint256 _value)
  onlyPayloadSize(3 * 32)
  checkTokenTransfer(_from)
  public returns (bool) {
    require(_to != address(0));
    require(_value <= balances[_from]);
    require(_value <= allowed[_from][msg.sender]);

    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    emit Transfer(_from, _to, _value);
    return true;
  }

  function approve(address _spender, uint256 _value)
  onlyPayloadSize(2 * 32)
  checkTokenTransfer(msg.sender)
  public returns (bool) {
     
     
     
     
    require((_value == 0) || (allowed[msg.sender][_spender] == 0));

    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
    return true;
  }

   
  function allowance(address _owner, address _spender) public view returns (uint256) {
    return allowed[_owner][_spender];
  }
}

contract BurnableToken is StandardToken {
  event Burn(address indexed from, uint256 value);

  function burn(address _from, uint256 _amount) public onlyOwner {
    require(_amount <= balances[_from]);
    totalSupply = totalSupply.sub(_amount);
    balances[_from] = balances[_from].sub(_amount);
    emit Transfer(_from, address(0), _amount);
    emit Burn(_from, _amount);
  }
}

 

contract MintableToken is BurnableToken {
  event Mint(address indexed to, uint256 amount);
  event MintFinished();

  bool public mintingFinished = false;
  address public minter;

  constructor() public {
    minter = msg.sender;
  }

  modifier canMint() {
    require(!mintingFinished);
    _;
  }

  modifier hasPermission() {
    require(msg.sender == owner || msg.sender == minter);
    _;
  }

  function () public payable {
    require(false);
  }

   
  function mint(address _to, uint256 _amount) canMint hasPermission public returns (bool) {
    totalSupply = totalSupply.add(_amount);
    balances[_to] = balances[_to].add(_amount);
    emit Mint(_to, _amount);
    emit Transfer(address(0), _to, _amount);
    return true;
  }

   
  function finishMinting() canMint onlyOwner public returns (bool) {
    mintingFinished = true;
    emit MintFinished();
    return true;
  }
}


contract VoltraCoin is MintableToken {

  string public constant name = "VoltraCoin";  
  string public constant symbol = "VLT";  
  uint8 public constant decimals = 18;  
   
  constructor() public {
    totalSupply = 0;
  }
}
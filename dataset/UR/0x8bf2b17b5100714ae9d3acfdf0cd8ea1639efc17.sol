 

pragma solidity >= 0.5.0 < 0.6.0;

library SafeMath {
  function add(uint a, uint b) internal pure returns (uint c) {
    c = a + b;
    require(c >= a);
  }
  function sub(uint a, uint b) internal pure returns (uint c) {
    require(b <= a);
    c = a - b;
  }
  function mul(uint a, uint b) internal pure returns (uint c) {
    c = a * b;
    require(a == 0 || c / a == b);
  }
  function div(uint a, uint b) internal pure returns (uint c) {
    require(b > 0);
    c = a / b;
  }
}

library NameFilter {

    function nameFilter(string memory _input)
        internal
        pure
        returns(bytes32)
    {
        bytes memory _temp = bytes(_input);
        uint256 _length = _temp.length;

         
        require (_length <= 16 && _length > 0, "string must be between 1 and 32 characters");
         
        require(_temp[0] != 0x20 && _temp[_length-1] != 0x20, "string cannot start or end with space");
         
        if (_temp[0] == 0x30)
        {
            require(_temp[1] != 0x78, "string cannot start with 0x");
            require(_temp[1] != 0x58, "string cannot start with 0X");
        }

         
        bool _hasNonNumber;

         
        for (uint256 i = 0; i < _length; i++)
        {
             
            if (_temp[i] > 0x40 && _temp[i] < 0x5b)
            {
                 
                _temp[i] = byte(uint8(_temp[i]) + 32);

                 
                if (_hasNonNumber == false)
                    _hasNonNumber = true;
            } else {
                require
                (
                     
                    _temp[i] == 0x20 ||
                     
                    (_temp[i] > 0x60 && _temp[i] < 0x7b) ||
                     
                    (_temp[i] > 0x2f && _temp[i] < 0x3a),
                    "string contains invalid characters"
                );
                 
                if (_temp[i] == 0x20)
                    require( _temp[i+1] != 0x20, "string cannot contain consecutive spaces");

                 
                if (_hasNonNumber == false && (_temp[i] < 0x30 || _temp[i] > 0x39))
                    _hasNonNumber = true;
            }
        }

        require(_hasNonNumber == true, "string cannot be only numbers");

        bytes32 _ret;
        assembly {
            _ret := mload(add(_temp, 32))
        }
        return (_ret);
    }
}

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address account) external view returns (uint256);
  function transfer(address recipient, uint256 amount) external returns (bool);
  function allowance(address owner, address spender) external view returns (uint256);
  function approve(address spender, uint256 amount) external returns (bool);
  function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
}


contract Owned {
  address public owner;
  address public newOwner;

  event OwnershipTransferred(address indexed _from, address indexed _to);

  constructor() public {
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address _newOwner) public onlyOwner {
    newOwner = _newOwner;
  }
  function acceptOwnership() public {
    require(msg.sender == newOwner);
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    newOwner = address(0);
  }
}

contract ERCBOOKS is Owned {
  using SafeMath for uint;
  using NameFilter for string;

  event tokenregister(address token, string name, string symbol);
  event playernameregister(bytes32 playername, address playeraddress);

  constructor() public {
    regtokens[0x0000000000000000000000000000000000000000].name = "Ether";
    regtokens[0x0000000000000000000000000000000000000000].symbol = "ETH";
    regtokens[0x0000000000000000000000000000000000000000].reg = true;
    emit tokenregister(0x0000000000000000000000000000000000000000, "Ether", "ETH");

    regtokens[0x514910771AF9Ca656af840dff83E8264EcF986CA].name = "ChainLink";
    regtokens[0x514910771AF9Ca656af840dff83E8264EcF986CA].symbol = "LINK";
    regtokens[0x514910771AF9Ca656af840dff83E8264EcF986CA].reg = true;
    emit tokenregister(0x514910771AF9Ca656af840dff83E8264EcF986CA, "ChainLink", "LINK");

    regtokens[0x0D8775F648430679A709E98d2b0Cb6250d2887EF].name = "BAT";
    regtokens[0x0D8775F648430679A709E98d2b0Cb6250d2887EF].symbol = "BAT";
    regtokens[0x0D8775F648430679A709E98d2b0Cb6250d2887EF].reg = true;
    emit tokenregister(0x0D8775F648430679A709E98d2b0Cb6250d2887EF, "BAT", "BAT");

    regtkncount = 3;
  }

  struct stkn {
    string name;
    string symbol;
    bool reg;
  }


  uint256 public tknregcost = 100000000000000000;
  mapping(address => stkn) public regtokens;
  uint256 public regtkncount;

  uint256 public nameregcost = 100000000000000000;
  mapping(address => bytes32) public playernames;
  mapping(bytes32 => address) public playernamelookup;


   
  function() external payable {
  }

   
  function registertoken(address token, string memory name, string memory symbol) public payable {
    require(msg.value >= tknregcost);
    require(regtokens[token].reg == false);
    regtokens[token].name = name;
    regtokens[token].symbol = symbol;
    regtokens[token].reg = true;
    regtkncount = regtkncount.add(1);
    emit tokenregister(token, name, symbol);
  }

  function registerplayername(string memory name) public payable {
    bytes32 fname = name.nameFilter();
    require(msg.value >= nameregcost);
    require(playernamelookup[fname] == 0x0000000000000000000000000000000000000000);
    if (keccak256(abi.encodePacked((playernames[msg.sender]))) != keccak256(abi.encodePacked(("")))) {
      playernamelookup[playernames[msg.sender]] = 0x0000000000000000000000000000000000000000;
    }
    playernames[msg.sender] = fname;
    playernamelookup[fname] = msg.sender;
    emit playernameregister(fname, msg.sender);
  }


   
  function settknregcost(uint256 cost) public onlyOwner() {
    tknregcost = cost;
  }
  function setnameregcost(uint256 cost) public onlyOwner() {
    nameregcost = cost;
  }

  function adminwithdrawal(IERC20 token, uint256 amount) public onlyOwner() {
  token.transfer(msg.sender, amount);
  }
  function clearETH() public onlyOwner() {
    address payable _owner = msg.sender;
    _owner.transfer(address(this).balance);
  }

}
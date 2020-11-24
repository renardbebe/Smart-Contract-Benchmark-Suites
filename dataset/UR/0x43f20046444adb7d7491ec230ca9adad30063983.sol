 

pragma solidity ^0.4.21;

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
    emit OwnershipTransferred(owner, newOwner);
    owner = newOwner;
  }
}

 
contract ERC20Basic {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract ERC20 is ERC20Basic {
  function allowance(address holder, address spender) external view returns (uint256);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  event Approval(address indexed holder, address indexed spender, uint256 value);
}

 
library SafeMath {

   
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    require(c / a == b);
    return c;
  }

   
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

   
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    require(b <= a);
    return a - b;
  }

   
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    require(c >= a);
    return c;
  }
}

contract SpindleToken is ERC20, Ownable {

    using SafeMath for uint256;

    string public constant name = 'SPINDLE';
    string public constant symbol = 'SPD';
    uint8 public constant decimals = 18;

    uint256 constant TOTAL_SPD = 10000000000;
    uint256 constant TOTAL_SUPPLY = TOTAL_SPD * (uint256(10) ** decimals);

    uint64 constant ICO_START_TIME = 1526083200;  
    uint64 constant RELEASE_B = ICO_START_TIME + 30 days;
    uint64 constant RELEASE_C = ICO_START_TIME + 60 days;
    uint64 constant RELEASE_D = ICO_START_TIME + 90 days;
    uint64 constant RELEASE_E = ICO_START_TIME + 180 days;
    uint64 constant RELEASE_F = ICO_START_TIME + 270 days;
    uint64[] RELEASE = new uint64[](6);

    mapping(address => uint256[6]) balances;
    mapping(address => mapping(address => uint256)) allowed;

     
    function SpindleToken() public {
        RELEASE[0] = ICO_START_TIME;
        RELEASE[1] = RELEASE_B;
        RELEASE[2] = RELEASE_C;
        RELEASE[3] = RELEASE_D;
        RELEASE[4] = RELEASE_E;
        RELEASE[5] = RELEASE_F;

        balances[msg.sender][0] = TOTAL_SUPPLY;
        emit Transfer(0x0, msg.sender, TOTAL_SUPPLY);
    }

     
    function totalSupply() external view returns (uint256) {
        return TOTAL_SUPPLY;
    }

     
    function transfer(address _to, uint256 _value) external returns (bool) {
        require(_to != address(0));
        require(_to != address(this));
        _updateLockUpAmountOf(msg.sender);

         
        balances[msg.sender][0] = balances[msg.sender][0].sub(_value);
        balances[_to][0] = balances[_to][0].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _holder) external view returns (uint256) {
        uint256[6] memory arr = lockUpAmountOf(_holder);
        return arr[0];
    }

     
    function lockUpAmountOf(address _holder) public view returns (
        uint256[6]
    ) {
        uint256[6] memory arr;
        arr[0] = balances[_holder][0];
        for (uint i = 1; i < RELEASE.length; i++) {
            arr[i] = balances[_holder][i];
            if(now >= RELEASE[i]){
                arr[0] = arr[0].add(balances[_holder][i]);
                arr[i] = 0;
            }
            else
            {
                arr[i] = balances[_holder][i];
            }
        }
        return arr;
    }

     
    function _updateLockUpAmountOf(address _address) internal {
        uint256[6] memory arr = lockUpAmountOf(_address);

        for(uint8 i = 0;i < arr.length; i++){
            balances[_address][i] = arr[i];
        }
    }

     
    function lockUpAmountStrOf(address _address) external view returns (
        address Address,
        string a,
        string b,
        string c,
        string d,
        string e,
        string f
    ) {
        address __address = _address;
        if(__address == address(0)) __address = msg.sender;

        uint256[6] memory arr = lockUpAmountOf(__address);

        return (
            __address,
            _uintToSPDStr(arr[0]),
            _uintToSPDStr(arr[1]),
            _uintToSPDStr(arr[2]),
            _uintToSPDStr(arr[3]),
            _uintToSPDStr(arr[4]),
            _uintToSPDStr(arr[5])
        );
    }

     
    function _uintToSPDStr(uint256 _amount) internal pure returns (string) {
        uint8 __tindex;
        uint8 __sindex;
        uint8 __left;
        uint8 __right;
        bytes memory __t = new bytes(30);   

         
        for(__tindex = 29; ; __tindex--){   
            if(__tindex == 11){             
                __t[__tindex] = byte(46);   
                continue;
            }
            __t[__tindex] = byte(48 + _amount%10);   
            _amount = _amount.div(10);
            if(__tindex == 0) break;
        }

         
        for(__left = 0; __left < 10; __left++) {      
            if(__t[__left]  != byte(48)) break;       
        }
        for(__right = 29; __right > 12; __right--){   
            if(__t[__right] != byte(48)) break;       
        }

        bytes memory __s = new bytes(__right - __left + 1 + 4);  

         
        __sindex = 0;
        for(__tindex = __left; __tindex <= __right; __tindex++){
            __s[__sindex] = __t[__tindex];
            __sindex++;
        }

        __s[__sindex++] = byte(32);   
        __s[__sindex++] = byte(83);   
        __s[__sindex++] = byte(80);   
        __s[__sindex++] = byte(68);   

        return string(__s);
    }

     
    function distribute(address _to, uint256 _a, uint256 _b, uint256 _c, uint256 _d, uint256 _e, uint256 _f) onlyOwner external returns (bool) {
        require(_to != address(0));
        _updateLockUpAmountOf(msg.sender);

        uint256 __total = 0;
        __total = __total.add(_a);
        __total = __total.add(_b);
        __total = __total.add(_c);
        __total = __total.add(_d);
        __total = __total.add(_e);
        __total = __total.add(_f);

        balances[msg.sender][0] = balances[msg.sender][0].sub(__total);

        balances[_to][0] = balances[_to][0].add(_a);
        balances[_to][1] = balances[_to][1].add(_b);
        balances[_to][2] = balances[_to][2].add(_c);
        balances[_to][3] = balances[_to][3].add(_d);
        balances[_to][4] = balances[_to][4].add(_e);
        balances[_to][5] = balances[_to][5].add(_f);

        emit Transfer(msg.sender, _to, __total);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool) {
        require(_to != address(0));
        require(_to != address(this));
        _updateLockUpAmountOf(_from);

        balances[_from][0] = balances[_from][0].sub(_value);
        balances[_to][0] = balances[_to][0].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) external returns (bool) {

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _holder, address _spender) external view returns (uint256) {
        return allowed[_holder][_spender];
    }
}
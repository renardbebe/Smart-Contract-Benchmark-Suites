 

pragma solidity >=0.5.0 <0.6.0;


library Strings {
   
  function strConcat(string memory _a, string memory _b, string memory _c, string memory _d, string memory _e) internal pure returns (string memory) {
      bytes memory _ba = bytes(_a);
      bytes memory _bb = bytes(_b);
      bytes memory _bc = bytes(_c);
      bytes memory _bd = bytes(_d);
      bytes memory _be = bytes(_e);
      string memory abcde = new string(_ba.length + _bb.length + _bc.length + _bd.length + _be.length);
      bytes memory babcde = bytes(abcde);
      uint k = 0; 
      for (uint i = 0; i < _ba.length; i++) babcde[k++] = _ba[i];
      for (uint i = 0; i < _bb.length; i++) babcde[k++] = _bb[i];
      for (uint i = 0; i < _bc.length; i++) babcde[k++] = _bc[i];
      for (uint i = 0; i < _bd.length; i++) babcde[k++] = _bd[i];
      for (uint i = 0; i < _be.length; i++) babcde[k++] = _be[i];
      return string(babcde);
    }

    function strConcat(string memory _a, string memory _b, string memory _c, string memory _d) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, _d, "");
    }

    function strConcat(string memory _a, string memory _b, string memory _c) internal pure returns (string memory) {
        return strConcat(_a, _b, _c, "", "");
    }

    function strConcat(string memory _a, string memory _b) internal pure returns (string memory) {
        return strConcat(_a, _b, "", "", "");
    }

    function uint2str(uint _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len - 1;
        while (_i != 0) {
            bstr[k--] = byte(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
    }
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
         
        require(b > 0);
        uint256 c = a / b;
         

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        uint256 c = a - b;

        return c;
    }

     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}



 
library Address {
     
    function isContract(address account) internal view returns (bool) {
        uint256 size;
         
         
         
         
         
         
         
        assembly { size := extcodesize(account) }
        return size > 0;
    }

    function toString(address _addr) internal pure returns(string memory) {
        bytes32 value = bytes32(uint256(_addr));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(51);
        str[0] = '0';
        str[1] = 'x';
        for (uint i = 0; i < 20; i++) {
            str[2+i*2] = alphabet[uint8(value[i + 12] >> 4)];
            str[3+i*2] = alphabet[uint8(value[i + 12] & 0x0f)];
        }
        return string(str);
    }
}



contract AccessERC20x {
    address private _ceo;
    address private _coo;
    address private _proxy;

    constructor () internal {
        _ceo = msg.sender;
        _coo = msg.sender;
        _proxy = msg.sender;
    }

    function ceoAddress() public view returns (address) {
        return _ceo;
    }

    function cooAddress() public view returns (address) {
        return _coo;
    }

    function proxyAddress() public view returns (address) {
        return _proxy;
    }

    modifier onlyCEO() {
        require(msg.sender == _ceo);
        _;
    }

    modifier onlyCLevel() {
        require(msg.sender == _ceo || msg.sender == _coo);
        _;
    }

    modifier onlyProxy() {
        require(msg.sender == _ceo || msg.sender == _coo || msg.sender == _proxy);
        _;
    }

    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));

        _ceo = _newCEO;
    }

    function setCOO(address _newCOO) external onlyCLevel {
        require(_newCOO != address(0));

        _coo = _newCOO;
    }

    function setProxy(address _newProxy) external onlyCLevel {
        require(_newProxy != address(0));

        _proxy = _newProxy;
    }
}



interface IERC20x {
    function totalSupply() external view returns (uint256);

    function balanceOf(address owner) external view returns (uint256);

    function tokenURI(address owner, uint256 index) external view returns (string memory);

    function approve(uint256 value) external returns (bool);

    function allowance(address owner) external view returns (uint256);

    function transferFrom(address from, address to, uint256 value) external returns (bool);

    function mintToken(address owner, uint256 value) external returns (bool);

    function burnToken(address owner, uint256 value) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed owner, uint256 value);
}



contract ERC20x is IERC20x, AccessERC20x {
    using SafeMath for uint256;

    mapping (address => uint256) private _balances;

    mapping (address => uint256) private _allowed;

    uint256 private _totalSupply;
	string internal _baseuri;

     
    function _transfer(address from, address to, uint256 value) internal {
        require(to != address(0));

        _balances[from] = _balances[from].sub(value);
        _balances[to] = _balances[to].add(value);
        emit Transfer(from, to, value);
    }

     
    function _mint(address account, uint256 value) internal {
        require(account != address(0));

        _totalSupply = _totalSupply.add(value);
        _balances[account] = _balances[account].add(value);
        emit Transfer(address(0), account, value);
    }

     
    function _burn(address account, uint256 value) internal {
        require(account != address(0));
		require(_balances[account] >= value);

        _totalSupply = _totalSupply.sub(value);
        _balances[account] = _balances[account].sub(value);
        emit Transfer(account, address(0), value);
    }

     
    function _burnFrom(address account, uint256 value) internal {
        _allowed[account] = _allowed[account].sub(value);
        _burn(account, value);
        emit Approval(account, _allowed[account]);
    }


     
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

     
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }

    function baseTokenURI() public view returns (string memory) {
        return _baseuri;
    }

    function tokenURI(address owner, uint256 index) public view returns (string memory) {
	    string memory p1;
	    string memory p2;

		p1 = Strings.strConcat("?wallet=", Address.toString(owner));
		p2 = Strings.strConcat("&index=",  Strings.uint2str(index));

        return Strings.strConcat(baseTokenURI(), Strings.strConcat(p1, p2));
    }

     
    function approve(uint256 value) public returns (bool) {
		require(value > 0);
		require(_balances[msg.sender] >= _allowed[msg.sender] + value);

        _allowed[msg.sender] = _allowed[msg.sender].add (value);
        emit Approval(msg.sender, value);
        return true;
    }

     
    function allowance(address owner) public view returns (uint256) {
        return _allowed[owner];
    }

     
    function transferFrom(address from, address to, uint256 value) public onlyProxy returns (bool) {
		require(value > 0);

        _allowed[from] = _allowed[from].sub(value);
        _transfer(from, to, value);
        emit Approval(from, _allowed[from]);
        return true;
    }

    function mintToken(address owner, uint256 value) public onlyProxy returns (bool) {
		require(value > 0);

        _mint(owner, value);
        return true;
    }

    function mintApprovedToken(address owner, uint256 value) public onlyProxy returns (bool) {
		require(value > 0);

        _mint(owner, value);

        _allowed[owner] = _allowed[owner].add (value);
        emit Approval(owner, value);
        return true;
    }

    function burnToken(address owner, uint256 value) public onlyProxy returns (bool) {
        _burnFrom(owner, value);
        return true;
    }
}



contract MoonDiaToken is ERC20x {
    string public name = "MoonDiaToken"; 
    string public symbol = "DIA";
    uint public decimals = 0;
    uint public INITIAL_SUPPLY = 60000000;

    constructor() public {
	    _baseuri = "https://reg.diana.io/api/token";

        _mint(msg.sender, INITIAL_SUPPLY);
    }

    function setBaseTokenURI(string memory _uri) public onlyCLevel {
        _baseuri = _uri;
    }
}
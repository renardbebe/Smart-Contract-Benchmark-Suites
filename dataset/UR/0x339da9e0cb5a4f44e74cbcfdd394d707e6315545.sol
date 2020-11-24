 

pragma solidity ^0.5.2;

 
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

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) onlyOwner public {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}

 
contract ERC223 {
    using SafeMath for uint256;

     
    function balanceOf(address who) public view returns (uint256);
    function totalSupply() public view returns (uint256);
    function transfer(address to, uint value) public returns (bool);
    function transfer(address to, uint value, bytes memory data) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint value, bytes indexed data);

     
    function name() public view returns (string memory);
    function symbol() public view returns (string memory);
    function decimals() public view returns (uint8);

     
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    function allowance(address owner, address spender) public view returns (uint256);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint value);
}

 
contract ContractReceiver {
     
    function tokenFallback(address _from, uint _value, bytes memory _data) public;
}

 
contract ZENI is ERC223, Ownable {
    using SafeMath for uint256;

    string private _name = "ZENI";
    string private _symbol = "ZENI";
    uint8 private _decimals = 8;
    uint256 private _initialSupply = 60e9 * 1e8;

    mapping (address => uint256) private _balances;
    mapping (address => mapping (address => uint256)) private _allowed;
    uint private _totalSupply;

    bool public mintingFinished = false;
    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public unlockUnixTime;

    event FrozenFunds(address indexed target, bool frozen);
    event LockedFunds(address indexed target, uint256 locked);
    event Burn(address indexed from, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event MintFinished();

     
    constructor() public {
        _totalSupply = _initialSupply;
        _balances[msg.sender] = _totalSupply;
    }


    function name() public view returns (string memory) {
        return _name;
    }

    function symbol() public view returns (string memory) {
        return _symbol;
    }

    function decimals() public view returns (uint8) {
        return _decimals;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256) {
        return _balances[_owner];
    }

     
    function freezeAccounts(address[] memory targets, bool isFrozen) public onlyOwner {
        require(targets.length > 0);

        for (uint j = 0; j < targets.length; j++) {
            require(targets[j] != address(0));
            frozenAccount[targets[j]] = isFrozen;
            emit FrozenFunds(targets[j], isFrozen);
        }
    }

     
    function lockupAccounts(address[] memory targets, uint[] memory unixTimes) public onlyOwner {
        require(
            targets.length > 0 &&
            targets.length == unixTimes.length
        );

        for(uint i = 0; i < targets.length; i++){
            require(unlockUnixTime[targets[i]] < unixTimes[i]);
            unlockUnixTime[targets[i]] = unixTimes[i];
            emit LockedFunds(targets[i], unixTimes[i]);
        }
    }

     
    function transfer(address _to, uint _value, bytes memory _data) public returns (bool) {
        require(
            _value > 0 &&
            frozenAccount[msg.sender] == false &&
            frozenAccount[_to] == false &&
            now > unlockUnixTime[msg.sender] &&
            now > unlockUnixTime[_to]
        );

        if(isContract(_to)) {
            return transferToContract(_to, _value, _data);
        }
        else {
            return transferToAddress(_to, _value, _data);
        }
    }

     
    function transfer(address _to, uint _value) public returns (bool) {
        require(
            _value > 0 &&
            frozenAccount[msg.sender] == false &&
            frozenAccount[_to] == false &&
            now > unlockUnixTime[msg.sender] &&
            now > unlockUnixTime[_to]
        );

        bytes memory empty;
        if (isContract(_to)) {
            return transferToContract(_to, _value, empty);
        } else {
            return transferToAddress(_to, _value, empty);
        }
    }

     
    function isContract(address _addr) private view returns (bool) {
        uint length;
        assembly {
             
            length := extcodesize(_addr)
        }
        return (length > 0);
    }

     
    function transferToAddress(address _to, uint _value, bytes memory _data) private returns (bool) {
        require(balanceOf(msg.sender) >= _value);
        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferToContract(address _to, uint _value, bytes memory _data) private returns (bool) {
        require(balanceOf(msg.sender) >= _value);
        ContractReceiver receiver = ContractReceiver(_to);
        receiver.tokenFallback(msg.sender, _value, _data);
        emit Transfer(msg.sender, _to, _value, _data);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(
            _to != address(0) &&
            _value > 0 &&
            _balances[_from] >= _value &&
            _allowed[_from][msg.sender] >= _value &&
            frozenAccount[_from] == false &&
            frozenAccount[_to] == false &&
            now > unlockUnixTime[_from] &&
            now > unlockUnixTime[_to]
        );

        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return _allowed[_owner][_spender];
    }

     
    function burn(address _from, uint256 _unitAmount) public onlyOwner {
        require(
            _unitAmount > 0 &&
            balanceOf(_from) >= _unitAmount
        );

        _balances[_from] = _balances[_from].sub(_unitAmount);
        _totalSupply = _totalSupply.sub(_unitAmount);
        emit Burn(_from, _unitAmount);
    }


    modifier canMint() {
        require(!mintingFinished);
        _;
    }

     
    function mint(address _to, uint256 _unitAmount) public onlyOwner canMint returns (bool) {
        require(_unitAmount > 0);

        _totalSupply = _totalSupply.add(_unitAmount);
        _balances[_to] = _balances[_to].add(_unitAmount);
        emit Mint(_to, _unitAmount);
        emit Transfer(address(0), _to, _unitAmount);
        return true;
    }

     
    function finishMinting() public onlyOwner canMint returns (bool) {
        mintingFinished = true;
        emit MintFinished();
        return true;
    }

     
    function distributeAirdrop(address[] memory addresses, uint256 amount) public returns (bool) {
        require(
            amount > 0 &&
            addresses.length > 0 &&
            frozenAccount[msg.sender] == false &&
            now > unlockUnixTime[msg.sender]
        );

        uint256 mulAmount = amount.mul(1e8);
        uint256 totalAmount = mulAmount.mul(addresses.length);
        require(_balances[msg.sender] >= totalAmount);

        for (uint i = 0; i < addresses.length; i++) {
            require(
                addresses[i] != address(0) &&
                frozenAccount[addresses[i]] == false &&
                now > unlockUnixTime[addresses[i]]
            );

            _balances[addresses[i]] = _balances[addresses[i]].add(mulAmount);
            emit Transfer(msg.sender, addresses[i], mulAmount);
        }
        _balances[msg.sender] = _balances[msg.sender].sub(totalAmount);
        return true;
    }

    function distributeAirdrop(address[] memory addresses, uint[] memory amounts) public returns (bool) {
        require(
            addresses.length > 0 &&
            addresses.length == amounts.length &&
            frozenAccount[msg.sender] == false &&
            now > unlockUnixTime[msg.sender]
        );

        uint256 totalAmount = 0;

        for(uint i = 0; i < addresses.length; i++){
            require(
                amounts[i] > 0 &&
                addresses[i] != address(0) &&
                frozenAccount[addresses[i]] == false &&
                now > unlockUnixTime[addresses[i]]
            );

            amounts[i] = amounts[i].mul(1e8);
            totalAmount = totalAmount.add(amounts[i]);
        }
        require(_balances[msg.sender] >= totalAmount);

        for (uint j = 0; j < addresses.length; j++) {
            _balances[addresses[j]] = _balances[addresses[j]].add(amounts[j]);
            emit Transfer(msg.sender, addresses[j], amounts[j]);
        }
        _balances[msg.sender] = _balances[msg.sender].sub(totalAmount);
        return true;
    }

     
    function collectTokens(address[] memory addresses, uint[] memory amounts) public onlyOwner returns (bool) {
        require(
            addresses.length > 0 &&
            addresses.length == amounts.length
        );

        uint256 totalAmount = 0;

        for (uint i = 0; i < addresses.length; i++) {
            require(
                amounts[i] > 0 &&
                addresses[i] != address(0) &&
                frozenAccount[addresses[i]] == false &&
                now > unlockUnixTime[addresses[i]]
            );

            amounts[i] = amounts[i].mul(1e8);
            require(_balances[addresses[i]] >= amounts[i]);
            _balances[addresses[i]] = _balances[addresses[i]].sub(amounts[i]);
            totalAmount = totalAmount.add(amounts[i]);
            emit Transfer(addresses[i], msg.sender, amounts[i]);
        }
        _balances[msg.sender] = _balances[msg.sender].add(totalAmount);
        return true;
    }

     
    function() external {
        revert();
    }

     
    function tokenFallback(address from_, uint256 value_, bytes memory data_) public pure {
        from_;
        value_;
        data_;
        revert();
    }
}
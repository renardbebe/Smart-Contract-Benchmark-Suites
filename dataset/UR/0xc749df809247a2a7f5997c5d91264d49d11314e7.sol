 

pragma solidity ^0.4.24;

 
contract ERC20 {
    function totalSupply() public view returns (uint256);

    function balanceOf(address _who) public view returns (uint256);

    function allowance(address _owner, address _spender)
    public view returns (uint256);

    function transfer(address _to, uint256 _value) public returns (bool);

    function approve(address _spender, uint256 _value)
    public returns (bool);

    function transferFrom(address _from, address _to, uint256 _value)
    public returns (bool);

    event Transfer(
        address indexed from,
        address indexed to,
        uint256 value
    );

    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

 
contract Ownable {
    address public owner;

    event OwnershipTransferred(
        address indexed previousOwner,
        address indexed newOwner
    );

     
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address _newOwner) public onlyOwner {
        _transferOwnership(_newOwner);
    }

     
    function _transferOwnership(address _newOwner) internal {
        require(_newOwner != address(0));
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}

 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b);

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0);  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a);
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a);

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0);
        return a % b;
    }
}

 
contract StandardToken is ERC20 {
    using SafeMath for uint256;

    mapping(address => uint256) balances;

    mapping (address => mapping (address => uint256)) internal allowed;

    uint256 totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances[_owner];
    }

     
    function allowance(
        address _owner,
        address _spender
    )
    public
    view
    returns (uint256)
    {
        return allowed[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances[msg.sender]);
        require(_to != address(0));

        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
    public
    returns (bool)
    {
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
        require(_to != address(0));

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
    public
    returns (bool)
    {
        allowed[msg.sender][_spender] = (
        allowed[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
    public
    returns (bool)
    {
        uint256 oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}

interface ERC223Receiver {

    function tokenFallback(address _from, uint256 _value, bytes _data) external;

}

 
contract SecureCryptoToken is StandardToken, Ownable {
    using SafeMath for uint256;

    event Release();
    event AddressLocked(address indexed _address, uint256 _time);
    event TokensReverted(address indexed _address, uint256 _amount);
    event AddressLockedByKYC(address indexed _address);
    event KYCVerified(address indexed _address);
    event TokensRevertedByKYC(address indexed _address, uint256 _amount);
    event SetTechAccount(address indexed _address);

    string public constant name = "Secure Crypto Payments";

    string public constant symbol = "SEC";

    string public constant standard = "ERC223";

    uint256 public constant decimals = 8;

    bool public released = false;
    bool public ignoreKYCLockup = false;

    address public tokensWallet;
    address public techAccount;

    mapping(address => uint) public lockedAddresses;
    mapping(address => bool) public verifiedKYCAddresses;

    modifier isReleased() {
        require(released || msg.sender == tokensWallet || msg.sender == owner || msg.sender == techAccount);
        require(lockedAddresses[msg.sender] <= now);
        if (!ignoreKYCLockup) {
            require(verifiedKYCAddresses[msg.sender]);
        }
        _;
    }

    modifier hasAddressLockupPermission() {
        require(msg.sender == owner || msg.sender == techAccount);
        _;
    }

    constructor() public {
        owner = 0xc8F9bFc1B5b77A44484b27ebF4583f1E0207EBb5;
        tokensWallet = owner;
        verifiedKYCAddresses[owner] = true;

        techAccount = 0x41D621De050A551F5f0eBb83D1332C75339B61E4;
        verifiedKYCAddresses[techAccount] = true;
        emit SetTechAccount(techAccount);

        totalSupply_ = 121000000 * (10 ** decimals);
        balances[tokensWallet] = totalSupply_;
        emit Transfer(0x0, tokensWallet, totalSupply_);
    }

    function lockAddress(address _address, uint256 _time) public hasAddressLockupPermission returns (bool) {
        require(_address != owner && _address != tokensWallet && _address != techAccount);
        require(balances[_address] == 0 && lockedAddresses[_address] == 0 && _time > now);
        lockedAddresses[_address] = _time;

        emit AddressLocked(_address, _time);
        return true;
    }

    function revertTokens(address _address) public hasAddressLockupPermission returns (bool) {
        require(lockedAddresses[_address] > now && balances[_address] > 0);

        uint256 amount = balances[_address];
        balances[tokensWallet] = balances[tokensWallet].add(amount);
        balances[_address] = 0;

        emit Transfer(_address, tokensWallet, amount);
        emit TokensReverted(_address, amount);

        return true;
    }

    function lockAddressByKYC(address _address) public hasAddressLockupPermission returns (bool) {
        require(released);
        require(balances[_address] == 0 && verifiedKYCAddresses[_address]);

        verifiedKYCAddresses[_address] = false;
        emit AddressLockedByKYC(_address);

        return true;
    }

    function verifyKYC(address _address) public hasAddressLockupPermission returns (bool) {
        verifiedKYCAddresses[_address] = true;
        emit KYCVerified(_address);

        return true;
    }

    function revertTokensByKYC(address _address) public hasAddressLockupPermission returns (bool) {
        require(!verifiedKYCAddresses[_address] && balances[_address] > 0);

        uint256 amount = balances[_address];
        balances[tokensWallet] = balances[tokensWallet].add(amount);
        balances[_address] = 0;

        emit Transfer(_address, tokensWallet, amount);
        emit TokensRevertedByKYC(_address, amount);

        return true;
    }

    function setKYCLockupIgnoring(bool _ignoreFlag) public onlyOwner {
        ignoreKYCLockup = _ignoreFlag;
    }

    function release() public onlyOwner returns (bool) {
        require(!released);
        released = true;
        emit Release();
        return true;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function transfer(address _to, uint256 _value) public isReleased returns (bool) {
        if (released && balances[_to] == 0) {
            verifiedKYCAddresses[_to] = true;
        }

        if (super.transfer(_to, _value)) {
            uint codeLength;
            assembly {
                codeLength := extcodesize(_to)
            }
            if (codeLength > 0) {
                ERC223Receiver receiver = ERC223Receiver(_to);
                receiver.tokenFallback(msg.sender, _value, msg.data);
            }

            return true;
        }

        return false;
    }

    function transferFrom(address _from, address _to, uint256 _value) public isReleased returns (bool) {
        if (released && balances[_to] == 0) {
            verifiedKYCAddresses[_to] = true;
        }

        if (super.transferFrom(_from, _to, _value)) {
            uint codeLength;
            assembly {
                codeLength := extcodesize(_to)
            }
            if (codeLength > 0) {
                ERC223Receiver receiver = ERC223Receiver(_to);
                receiver.tokenFallback(_from, _value, msg.data);
            }

            return true;
        }

        return false;
    }

    function approve(address _spender, uint256 _value) public isReleased returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public isReleased returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public isReleased returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != owner);
        require(lockedAddresses[newOwner] < now);
        address oldOwner = owner;
        super.transferOwnership(newOwner);

        if (oldOwner != tokensWallet) {
            allowed[tokensWallet][oldOwner] = 0;
            emit Approval(tokensWallet, oldOwner, 0);
        }

        if (owner != tokensWallet) {
            allowed[tokensWallet][owner] = balances[tokensWallet];
            emit Approval(tokensWallet, owner, balances[tokensWallet]);
        }

        verifiedKYCAddresses[newOwner] = true;
        emit KYCVerified(newOwner);
    }

    function changeTechAccountAddress(address _address) public onlyOwner {
        require(_address != address(0) && _address != techAccount);
        require(lockedAddresses[_address] < now);

        techAccount = _address;
        emit SetTechAccount(techAccount);

        verifiedKYCAddresses[_address] = true;
        emit KYCVerified(_address);
    }

}
 

 

pragma solidity ^0.5.0;

 
contract Context {
     
     
    constructor () internal { }
     

    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this;  
        return msg.data;
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = _msgSender();
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.14;

interface IERC20 {
    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function approve(address _spender, uint256 _value) external returns (bool);
}

 

pragma solidity ^0.5.14;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

     
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

     
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
         
        require(b > 0, errorMessage);
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

     
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

 

pragma solidity ^0.5.14;


 
contract Freezer is Ownable {
    event Freezed(address dsc);
    event Unfreezed(address dsc);

    mapping (address => bool) public freezing;

    modifier isFreezed (address src) {
        require(freezing[src] == false, "Freeze/Fronzen-Account");
        _;
    }

     
    function freeze(address _dsc) external onlyOwner {
        require(_dsc != address(0), "Freeze/Zero-Address");
        require(freezing[_dsc] == false, "Freeze/Already-Freezed");

        freezing[_dsc] = true;

        emit Freezed(_dsc);
    }

     
    function unFreeze(address _dsc) external onlyOwner {
        require(freezing[_dsc] == true, "Freeze/Already-Unfreezed");

        delete freezing[_dsc];

        emit Unfreezed(_dsc);
    }
}

 

pragma solidity ^0.5.14;


 
contract SendLimiter is Ownable {
    event SendWhitelisted(address dsc);
    event SendDelisted(address dsc);
    event SendUnlocked();

    bool public sendLimit;
    mapping (address => bool) public sendWhitelist;

     
    constructor() public {
        sendLimit = true;
        sendWhitelist[msg.sender] = true;
    }

    modifier isAllowedSend (address dsc) {
        if (sendLimit) require(sendWhitelist[dsc], "SendLimiter/Not-Allow-Address");
        _;
    }

     
    function addAllowSender(address _whiteAddress) public onlyOwner {
        require(_whiteAddress != address(0), "SendLimiter/Not-Allow-Zero-Address");
        sendWhitelist[_whiteAddress] = true;
        emit SendWhitelisted(_whiteAddress);
    }

     
    function addAllowSenders(address[] memory _whiteAddresses) public onlyOwner {
        for (uint256 i = 0; i < _whiteAddresses.length; i++) {
            addAllowSender(_whiteAddresses[i]);
        }
    }

     
    function removeAllowedSender(address _whiteAddress) public onlyOwner {
        require(_whiteAddress != address(0), "SendLimiter/Not-Allow-Zero-Address");
        delete sendWhitelist[_whiteAddress];
        emit SendDelisted(_whiteAddress);
    }

     
    function removeAllowedSenders(address[] memory _whiteAddresses) public onlyOwner {
        for (uint256 i = 0; i < _whiteAddresses.length; i++) {
            removeAllowedSender(_whiteAddresses[i]);
        }
    }

     
    function sendUnlock() external onlyOwner {
        sendLimit = false;
        emit SendUnlocked();
    }
}

 

pragma solidity ^0.5.14;


 
contract ReceiveLimiter is Ownable {
    event ReceiveWhitelisted(address dsc);
    event ReceiveDelisted(address dsc);
    event ReceiveUnlocked();

    bool public receiveLimit;
    mapping (address => bool) public receiveWhitelist;

     
    constructor() public {
        receiveLimit = true;
        receiveWhitelist[msg.sender] = true;
    }

    modifier isAllowedReceive (address dsc) {
        if (receiveLimit) require(receiveWhitelist[dsc], "Limiter/Not-Allow-Address");
        _;
    }

     
    function addAllowReceiver(address _whiteAddress) public onlyOwner {
        require(_whiteAddress != address(0), "Limiter/Not-Allow-Zero-Address");
        receiveWhitelist[_whiteAddress] = true;
        emit ReceiveWhitelisted(_whiteAddress);
    }

     
    function addAllowReceivers(address[] memory _whiteAddresses) public onlyOwner {
        for (uint256 i = 0; i < _whiteAddresses.length; i++) {
            addAllowReceiver(_whiteAddresses[i]);
        }
    }

     
    function removeAllowedReceiver(address _whiteAddress) public onlyOwner {
        require(_whiteAddress != address(0), "Limiter/Not-Allow-Zero-Address");
        delete receiveWhitelist[_whiteAddress];
        emit ReceiveDelisted(_whiteAddress);
    }

     
    function removeAllowedReceivers(address[] memory _whiteAddresses) public onlyOwner {
        for (uint256 i = 0; i < _whiteAddresses.length; i++) {
            removeAllowedReceiver(_whiteAddresses[i]);
        }
    }

     
    function receiveUnlock() external onlyOwner {
        receiveLimit = false;
        emit ReceiveUnlocked();
    }
}

 

pragma solidity ^0.5.14;







 
contract TokenAsset is Ownable, IERC20, SendLimiter, ReceiveLimiter, Freezer {
    using SafeMath for uint256;

    string public constant name = "tokenAsset";
    string public constant symbol = "NTB";
    uint8 public constant decimals = 18;
    uint256 public totalSupply = 200000000e18;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping(address => uint256)) public allowance;

    
    
    constructor() SendLimiter() ReceiveLimiter() public {
        balanceOf[msg.sender] = totalSupply;
    }

     
    function transfer (
        address _to,
        uint256 _value
    ) external isAllowedSend(msg.sender) isAllowedReceive(_to) isFreezed(msg.sender) returns (bool) {
        require(_to != address(0), "TokenAsset/Not-Allow-Zero-Address");

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

     
    function transferFrom (
        address _from,
        address _to,
        uint256 _value
    ) external isAllowedSend(_from) isAllowedReceive(_to) isFreezed(_from) returns (bool) {
        require(_from != address(0), "TokenAsset/Not-Allow-Zero-Address");
        require(_to != address(0), "TokenAsset/Not-Allow-Zero-Address");

        balanceOf[_from] = balanceOf[_from].sub(_value);
        balanceOf[_to] = balanceOf[_to].add(_value);
        allowance[_from][msg.sender] = allowance[_from][msg.sender].sub(_value);

        emit Transfer(_from, _to, _value);

        return true;
    }

     
    function burn (
        uint256 _value
    ) external returns (bool) {
        require(_value <= balanceOf[msg.sender]);

        balanceOf[msg.sender] = balanceOf[msg.sender].sub(_value);
        totalSupply = totalSupply.sub(_value);

        emit Transfer(msg.sender, address(0), _value);
        
        return true;
    }

     
    function approve (
        address _spender,
        uint256 _value
    ) external returns (bool) {
        require(_spender != address(0), "TokenAsset/Not-Allow-Zero-Address");
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);

        return true;
    }
}
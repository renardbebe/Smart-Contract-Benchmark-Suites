 

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

contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
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

contract Bridge is Ownable {

    using SafeMath for uint256;

    enum Stage { Deployed, Claim, Pause, Swap, Finished }

    Stage public currentStage;

    uint256 public minTransferAmount;
    uint256 constant public border = 10**14;

    struct Transfer {
        string accountName;
        string accountOpenkey;
        uint256 amount;
    }

    mapping(address => Transfer) public claims;
    mapping(address => Transfer[]) public swaps;
    mapping(string => string) public nameToOpenkey;
    address[] public claimParticipants;
    address[] public swapParticipants;

    IERC20 public token;

    event NextStage(address _sender, Stage _currentStage, uint256 _timestamp);
    event Swap(address _from, string accountName, string accountOpenkey, uint256 amount, uint256 timestamp);
    event Claim(address _from, string accountName, string accountOpenkey, uint256 amount, uint256 timestamp);

     
    modifier stageAfter(Stage _stage) {
        require(uint256(currentStage) > uint256(_stage));
        _;
    }

     
    modifier stageBefore(Stage _stage) {
        require(uint256(currentStage) < uint256(_stage));
        _;
    }

    constructor(IERC20 _token, uint256 _minTransferAmount) public {
        require(_minTransferAmount >= border, 'invalid _minTransferAmount');
        minTransferAmount = _minTransferAmount;
        token = _token;
        currentStage = Stage.Deployed;
    }

     
    function convert(string memory _accountName, string memory _accountOpenkey, uint256 _amount)
    stageAfter(Stage.Deployed)
    stageBefore(Stage.Finished)
    public {

        require(currentStage != Stage.Pause, "You can't convert tokens during a pause");        
         
        require(isValidAccountName(_accountName), "invalid account name");
        require(isValidOpenkey(_accountOpenkey), "invalid openkey");
         
        require(_amount >= minTransferAmount, "too few tokens");

        string memory openkey = nameToOpenkey[_accountName];
        
        require(
                keccak256(abi.encodePacked(openkey)) == keccak256(abi.encodePacked(_accountOpenkey)) || 
                bytes(openkey).length == 0,
                "account already exist with another openkey"
            );
    
         
        uint256 intValue = _amount.div(border);
        uint256 roundedValue = intValue.mul(border);
        
         
        require(token.transferFrom(msg.sender, address(this), roundedValue), "transferFrom failed");

        if (currentStage == Stage.Claim) {
            
            string memory registeredAccountName = claims[msg.sender].accountName;
            require(
                keccak256(abi.encodePacked(registeredAccountName)) == keccak256(abi.encodePacked(_accountName)) || 
                bytes(registeredAccountName).length == 0,
                "you have already registered an account"
            );

             
            addNewClaimParticipant(msg.sender);
            uint256 previousAmount = claims[msg.sender].amount;
            claims[msg.sender] = Transfer(_accountName, _accountOpenkey, roundedValue.add(previousAmount));
            emit Claim(msg.sender, _accountName, _accountOpenkey, roundedValue, now);
        
        } else if(currentStage == Stage.Swap) {
             
            addNewSwapParticipant(msg.sender);
            swaps[msg.sender].push(Transfer(_accountName, _accountOpenkey, roundedValue));
            emit Swap(msg.sender, _accountName, _accountOpenkey, roundedValue, now);
        }
        
        if(bytes(openkey).length == 0) {
            nameToOpenkey[_accountName] = _accountOpenkey;
        }
    }

    function nextStage() onlyOwner stageBefore(Stage.Finished) public {
         
        uint256 next = uint256(currentStage) + 1;
        currentStage = Stage(next);

        emit NextStage(msg.sender, currentStage, now);
    }

    function addNewClaimParticipant(address _addr) private {
        if (claims[_addr].amount == uint256(0)) {
            claimParticipants.push(_addr);
        }
    }

        
    function addNewSwapParticipant(address _addr) private {
        if (swaps[_addr].length == uint256(0)) {
            swapParticipants.push(_addr);
        }
    }

    function isValidOpenkey(string memory str) public pure returns (bool) {
        bytes memory b = bytes(str);
        if(b.length != 53) return false;

         
        if (bytes1(b[0]) != 0x45 || bytes1(b[1]) != 0x4F || bytes1(b[2]) != 0x53)
            return false;

        for(uint i = 3; i<b.length; i++){
            bytes1 char = b[i];

             
            if(!(char >= 0x31 && char <= 0x39) &&
               !(char >= 0x41 && char <= 0x48) &&
               !(char >= 0x4A && char <= 0x4E) &&
               !(char >= 0x50 && char <= 0x5A) &&
               !(char >= 0x61 && char <= 0x6B) &&
               !(char >= 0x6D && char <= 0x7A)) 
            return false;
        }

        return true;
    }

    function isValidAccountName(string memory account) public pure returns (bool) {
        bytes memory b = bytes(account);
        if (b.length != 12) return false;

        for(uint i = 0; i<b.length; i++){
            bytes1 char = b[i];

             
            if(!(char >= 0x61 && char <= 0x7A) && 
               !(char >= 0x31 && char <= 0x35) && 
               !(char == 0x2E)) 
            return  false;
        }
        
        return true;
    }

    function isValidAccount(string memory _accountName, string memory _accountOpenkey) public pure returns (bool) {
            return(isValidAccountName(_accountName) && isValidOpenkey(_accountOpenkey));
        }
        
}
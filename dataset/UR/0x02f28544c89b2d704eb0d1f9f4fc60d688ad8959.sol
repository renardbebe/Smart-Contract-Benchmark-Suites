 

pragma solidity ^0.5.8;
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b; require(c >= a,"Can not add Negative Values"); }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a, "Result can not be negative"); c = a - b;  }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b; require(a == 0 || c / a == b,"Dived by Zero protection"); }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0,"Devide by Zero protection"); c = a / b; }
}

 
 
 
 
contract ERC20Interface {
    function totalSupply() external view returns (uint);
    function balanceOf(address owner) public view returns (uint256 balance);
    function allowance(address owner, address spender) public view returns (uint remaining);
    function transfer(address to, uint value) public returns (bool success);
    function approve(address spender, uint value) public returns (bool success);
    function transferFrom(address from, address to, uint value) public returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract ERC1404 is ERC20Interface {
    function detectTransferRestriction (address from, address to, uint256 value) public view returns (uint8);
    function messageForTransferRestriction (uint8 restrictionCode) public view returns (string memory);
}

 
 
 
contract Owned {
    address public owner;
    address internal newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    constructor() public {  
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner, "Only the contract owner can execute this function");
        _;
    }

    function transferOwnership(address _newOwner) external onlyOwner {
        newOwner = _newOwner;
    }

    function acceptOwnership() external {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
}

contract Managed is Owned {
    mapping (address => bool) public managers;


    modifier onlyManager () {
        require(managers[msg.sender], "Only managers may perform this action");
        _;
    }

    function addManager (address managerAddress) public onlyOwner {
        managers[managerAddress] = true;
    }

    function removeManager (address managerAddress) external onlyOwner {
        managers[managerAddress] = false;
    }
}

 
contract Whitelist is Managed {
    mapping(address => bytes1) public whiteList;
    bytes1 internal listRule;
    bytes1 internal constant WHITELISTED_CAN_RX_CODE = 0x01;   
    bytes1 internal constant WHITELISTED_CAN_TX_CODE = 0x02;   
    bytes1 internal constant WHITELISTED_FREEZE_CODE = 0x04;   

    function frozen(address _account) public view returns (bool){  
        return (WHITELISTED_FREEZE_CODE == (whiteList[_account] & WHITELISTED_FREEZE_CODE));  
    }

    function addToSendAllowed(address _to) external onlyManager {
        whiteList[_to] = whiteList[_to] | WHITELISTED_CAN_TX_CODE;  
    }

    function addToReceiveAllowed(address _to) external onlyManager {
        whiteList[_to] = whiteList[_to] | WHITELISTED_CAN_RX_CODE;  
    }

    function removeFromSendAllowed(address _to) public onlyManager {
        if (WHITELISTED_CAN_TX_CODE == (whiteList[_to] & WHITELISTED_CAN_TX_CODE))  {  
            whiteList[_to] = whiteList[_to] ^ WHITELISTED_CAN_TX_CODE;  
        }
    }

    function removeFromReceiveAllowed(address _to) public onlyManager {
        if (WHITELISTED_CAN_RX_CODE == (whiteList[_to] & WHITELISTED_CAN_RX_CODE))  {
            whiteList[_to] = whiteList[_to] ^ WHITELISTED_CAN_RX_CODE;
        }
    }

    function removeFromBothSendAndReceiveAllowed (address _to) external onlyManager {
        removeFromSendAllowed(_to);
        removeFromReceiveAllowed(_to);
    }

     
    function freeze(address _to) external onlyOwner {
        whiteList[_to] = whiteList[_to] | WHITELISTED_FREEZE_CODE;  
    }

    function unFreeze(address _to) external onlyOwner {
        if (WHITELISTED_FREEZE_CODE == (whiteList[_to] & WHITELISTED_FREEZE_CODE )) {  
            whiteList[_to] = whiteList[_to] ^ WHITELISTED_FREEZE_CODE;  
        }
    }

     
    function setWhitelistRule(byte _newRule) external onlyOwner {
        listRule = _newRule;
    }
    function getWhitelistRule() external view returns (byte){
        return listRule;
    }
}

 
 
contract SPTToken is ERC1404, Owned, Whitelist {
    using SafeMath for uint;

    string public symbol;
    string public  name;
    uint8 public decimals;
    uint public _totalSupply;
    uint8 internal restrictionCheck;

    mapping(address => uint) public balances;
    mapping(address => mapping(address => uint)) allowed;


     
     
    constructor() public {
        symbol = "SMPT";
        name = "Smart Pharma Token";
        decimals = 8;
        _totalSupply = 100000000000000000;
        balances[msg.sender] = _totalSupply;
        managers[msg.sender] = true;
        listRule = 0x00;  
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    modifier transferAllowed(address _from, address _to, uint256 _amount ) {
        require(!frozen(_to) && !frozen(_from), "One of the Accounts are Frozen");   
        if ((listRule & WHITELISTED_CAN_TX_CODE) != 0) {  
            require(WHITELISTED_CAN_TX_CODE == (whiteList[_from] & WHITELISTED_CAN_TX_CODE), "Sending Account is not whitelisted");  
        }
        if ((listRule & WHITELISTED_CAN_RX_CODE) != 0) {  
            require(WHITELISTED_CAN_RX_CODE == (whiteList[_to] & WHITELISTED_CAN_RX_CODE),"Receiving Account is not Whitelisted");  
        }
        _;
    }

     
     
    function totalSupply() external view returns (uint) {
        return _totalSupply.sub(balances[address(0)]);
    }

     
     
    function balanceOf(address owner) public view returns (uint256) {
        return balances[owner];
    }

     
     
     
     
     
    function transfer(address _to, uint _value)  public transferAllowed(msg.sender, _to, _value) returns (bool) {
        require((_to != address(0)) && (_to != address(this)));  
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
     
     
    function approve(address spender, uint value) public transferAllowed(msg.sender, spender, value) returns (bool) {
        allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
     
    function transferFrom(address _from, address _to, uint _value) public transferAllowed(_from, _to, _value) returns (bool) {
         
        require((_to != address(0)) && (_to != address(this)));  
        balances[_from] = balances[_from].sub(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint) {
        return allowed[owner][spender];
    }

     
    function () payable external {
        revert();
    }

     
    function transferAnyERC20Token(address tokenAddress, uint tokens) public onlyOwner returns (bool success) {
        return ERC20Interface(tokenAddress).transfer(owner, tokens);
    }

     
    function detectTransferRestriction (address _from, address _to, uint256 _value) public view returns (uint8 restrictionCode)
    {
        restrictionCode = 0;  
        if ( WHITELISTED_CAN_TX_CODE == (listRule & WHITELISTED_CAN_TX_CODE) ) {  
            if (!(WHITELISTED_CAN_TX_CODE == (whiteList[_to] & WHITELISTED_CAN_TX_CODE)) ) {  
                restrictionCode += 1;  
            }
        }
        if (WHITELISTED_CAN_RX_CODE == (listRule & WHITELISTED_CAN_RX_CODE)){  
            if (!(WHITELISTED_CAN_RX_CODE == (whiteList[_from] & WHITELISTED_CAN_RX_CODE))) {
                restrictionCode += 2;  
            }
        }
        if ((WHITELISTED_FREEZE_CODE == (whiteList[_from] & WHITELISTED_FREEZE_CODE)) ) {  
            restrictionCode += 4;  
        }
        if ((WHITELISTED_FREEZE_CODE == (whiteList[_to] & WHITELISTED_FREEZE_CODE)) ) {  
            restrictionCode += 8;  
        }

        if (balanceOf(_from) < _value) {
            restrictionCode += 16;  
        }

        return restrictionCode;
    }

     
    function messageForTransferRestriction (uint8 _restrictionCode) public view returns (string memory _message) {
        _message = "Transfer Allowed";   
        if (_restrictionCode >= 16) {
            _message = "Insufficient Balance to send";
        } else if (_restrictionCode >= 8) {
            _message = "To Account is Frozen, contact provider";
        } else if (_restrictionCode >= 4) {
            _message = "From Account is Frozen, contact provider";
        } else if (_restrictionCode >= 3) {
            _message = "Both Sending and receiving address has not been KYC Approved";
        } else if (_restrictionCode >= 2) {
            _message = "Receiving address has not been KYC Approved";
        } else if (_restrictionCode >= 1) {
            _message = "Sending address has not been KYC Approved";
        }
        return _message;
    }
}
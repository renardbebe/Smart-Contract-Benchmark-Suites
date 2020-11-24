 

pragma solidity ^0.4.9;

contract ERC20 {
    function totalSupply() constant returns (uint256 totalSupply);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) returns (bool success);
    function approve(address _spender, uint256 _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);
}

 
contract MainstreetToken is ERC20 {
    string public name = 'Mainstreet Token';              
    uint8 public decimals = 18;              
    string public symbol = 'MIT';            
    string public version = 'MIT_0.1';

    mapping (address => uint) ownerMIT;
    mapping (address => mapping (address => uint)) allowed;
    uint public totalMIT;
    uint public start;

    address public mainstreetCrowdfund;

    address public intellisys;

    bool public testing;

    modifier fromCrowdfund() {
        if (msg.sender != mainstreetCrowdfund) {
            throw;
        }
        _;
    }

    modifier isActive() {
        if (block.timestamp < start) {
            throw;
        }
        _;
    }

    modifier isNotActive() {
        if (!testing && block.timestamp >= start) {
            throw;
        }
        _;
    }

    modifier recipientIsValid(address recipient) {
        if (recipient == 0 || recipient == address(this)) {
            throw;
        }
        _;
    }

    modifier allowanceIsZero(address spender, uint value) {
         
         
         
         
        if ((value != 0) && (allowed[msg.sender][spender] != 0)) {
            throw;
        }
        _;
    }

     
    function MainstreetToken(address _mainstreetCrowdfund, address _intellisys, uint _start, bool _testing) {
        mainstreetCrowdfund = _mainstreetCrowdfund;
        intellisys = _intellisys;
        start = _start;
        testing = _testing;
    }

     
    function addTokens(address recipient, uint MIT) external isNotActive fromCrowdfund {
        ownerMIT[recipient] += MIT;
        uint intellisysMIT = MIT / 10;
        ownerMIT[intellisys] += intellisysMIT;
        totalMIT += MIT + intellisysMIT;
        Transfer(0x0, recipient, MIT);
        Transfer(0x0, intellisys, intellisysMIT);
    }

     
    function totalSupply() constant returns (uint256 totalSupply) {
        totalSupply = totalMIT;
    }

     
    function balanceOf(address _owner) constant returns (uint256 balance) {
        balance = ownerMIT[_owner];
    }

     
    function transfer(address _to, uint256 _value) isActive recipientIsValid(_to) returns (bool success) {
        if (ownerMIT[msg.sender] >= _value) {
            ownerMIT[msg.sender] -= _value;
            ownerMIT[_to] += _value;
            Transfer(msg.sender, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) isActive recipientIsValid(_to) returns (bool success) {
        if (allowed[_from][msg.sender] >= _value && ownerMIT[_from] >= _value) {
            ownerMIT[_to] += _value;
            ownerMIT[_from] -= _value;
            allowed[_from][msg.sender] -= _value;
            Transfer(_from, _to, _value);
            return true;
        } else {
            return false;
        }
    }

     
    function approve(address _spender, uint256 _value) isActive allowanceIsZero(_spender, _value) returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) constant returns (uint256 remaining) {
        remaining = allowed[_owner][_spender];
    }
}


 
contract MainstreetCrowdfund {

    uint public start;
    uint public end;

    mapping (address => uint) public senderETH;
    mapping (address => uint) public senderMIT;
    mapping (address => uint) public recipientETH;
    mapping (address => uint) public recipientMIT;
    mapping (address => uint) public recipientExtraMIT;

    uint public totalETH;
    uint public limitETH;

    uint public bonus1StartETH;
    uint public bonus2StartETH;

    mapping (address => bool) public whitelistedAddresses;

    address public exitAddress;
    address public creator;

    MainstreetToken public mainstreetToken;

    event MITPurchase(address indexed sender, address indexed recipient, uint ETH, uint MIT);

    modifier saleActive() {
        if (address(mainstreetToken) == 0) {
            throw;
        }
        if (block.timestamp < start || block.timestamp >= end) {
            throw;
        }
        if (totalETH + msg.value > limitETH) {
            throw;
        }
        _;
    }

    modifier hasValue() {
        if (msg.value == 0) {
            throw;
        }
        _;
    }

    modifier senderIsWhitelisted() {
        if (whitelistedAddresses[msg.sender] != true) {
            throw;
        }
        _;
    }

    modifier recipientIsValid(address recipient) {
        if (recipient == 0 || recipient == address(this)) {
            throw;
        }
        _;
    }

    modifier isCreator() {
        if (msg.sender != creator) {
            throw;
        }
        _;
    }

    modifier tokenContractNotSet() {
        if (address(mainstreetToken) != 0) {
            throw;
        }
        _;
    }

     
    function MainstreetCrowdfund(uint _start, uint _end, uint _limitETH, uint _bonus1StartETH, uint _bonus2StartETH, address _exitAddress, address whitelist1, address whitelist2, address whitelist3) {
        creator = msg.sender;
        start = _start;
        end = _end;
        limitETH = _limitETH;
        bonus1StartETH = _bonus1StartETH;
        bonus2StartETH = _bonus2StartETH;

        whitelistedAddresses[whitelist1] = true;
        whitelistedAddresses[whitelist2] = true;
        whitelistedAddresses[whitelist3] = true;
        exitAddress = _exitAddress;
    }

     
    function setTokenContract(MainstreetToken _mainstreetToken) external isCreator tokenContractNotSet {
        mainstreetToken = _mainstreetToken;
    }

     
    function purchaseMIT(address recipient) external senderIsWhitelisted payable saleActive hasValue recipientIsValid(recipient) returns (uint increaseMIT) {

         
        if (!exitAddress.send(msg.value)) {
            throw;
        }

         
        senderETH[msg.sender] += msg.value;
        recipientETH[recipient] += msg.value;
        totalETH += msg.value;

         
        uint MIT = msg.value * 10;    

         
        if (block.timestamp - start < 2 weeks) {
            MIT += MIT / 10;     
        }
        else if (block.timestamp - start < 5 weeks) {
            MIT += MIT / 20;     
        }

         
        senderMIT[msg.sender] += MIT;
        recipientMIT[recipient] += MIT;

         
        uint oldExtra = recipientExtraMIT[recipient];

         
        if (recipientETH[recipient] >= bonus2StartETH) {
            recipientExtraMIT[recipient] = (recipientMIT[recipient] * 75) / 1000;       
        }
        else if (recipientETH[recipient] >= bonus1StartETH) {
            recipientExtraMIT[recipient] = (recipientMIT[recipient] * 375) / 10000;       
        }

         
        increaseMIT = MIT + (recipientExtraMIT[recipient] - oldExtra);

         
        mainstreetToken.addTokens(recipient, increaseMIT);

         
        MITPurchase(msg.sender, recipient, msg.value, increaseMIT);
    }

}
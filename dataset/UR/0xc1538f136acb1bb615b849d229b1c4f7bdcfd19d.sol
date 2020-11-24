 

pragma solidity 0.4.25;

 
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

contract Developed {
    using SafeMath for uint256;
    
    struct Developer {
        address account;
        uint256 comission;
        bool isCollab;
    }
    
     
    string public name;
    string public symbol;
    uint8 public decimals = 0;
     
    uint64 public totalSupply;


     
    uint public payoutBalance = 0;
    uint public payoutIndex = 0;
    bool public paused = false;
    uint public lastPayout;


    constructor() public payable {        
        Developer memory dev = Developer(msg.sender, 1 szabo, true);
        developers[msg.sender] = dev;
        developerAccounts.push(msg.sender);
        name = "MyHealthData Divident Token";
        symbol = "MHDDEV";
        totalSupply = 1 szabo;
    }
    
     
    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
    
    mapping(address => Developer) internal developers;
    address[] public developerAccounts;
    
    mapping (address => mapping (address => uint256)) private _allowed;
    
    modifier comissionLimit (uint256 value) {
        require(value < 1 szabo, "Invalid value");
        _;
    }

    modifier whenNotPaused () {
        require(paused == false, "Transfers paused, to re-enable transfers finish the payout round.");
        _;
    }

    function () external payable {}

    function newDeveloper(address _devAccount, uint64 _comission, bool _isCollab) public comissionLimit(_comission) returns(address) {
        require(_devAccount != address(0), "Invalid developer account");
        
        bool isCollab = _isCollab;
        Developer storage devRequester = developers[msg.sender];
         
        if (!devRequester.isCollab) {
            isCollab = false;
        }
        
        require(devRequester.comission>=_comission, "The developer requester must have comission balance in order to sell her commission");
        devRequester.comission = devRequester.comission.sub(_comission);
        
        Developer memory dev = Developer(_devAccount, _comission, isCollab);
        developers[_devAccount] = dev;

        developerAccounts.push(_devAccount);
        return _devAccount;
    }

    function totalDevelopers() public view returns (uint256) {
        return developerAccounts.length;
    }

    function getSingleDeveloper(address _devID) public view returns (address devAccount, uint256 comission, bool isCollaborator) {
        require(_devID != address(0), "Dev ID must be greater than zero");
         
        Developer memory dev = developers[_devID];
        devAccount = dev.account;
        comission = dev.comission;
        isCollaborator = dev.isCollab;
        return;
    }
    
    function payComission() public returns (bool success) {
        require (lastPayout < now - 14 days, "Only one payout every two weeks allowed");
        paused = true;
        if (payoutIndex == 0)
            payoutBalance = address(this).balance;
        for (uint i = payoutIndex; i < developerAccounts.length; i++) {
            Developer memory dev = developers[developerAccounts[i]];
            if (dev.comission > 0) {
                uint valueToSendToDev = (payoutBalance.mul(dev.comission)).div(1 szabo);

                 
                 
                 
                dev.account.send(valueToSendToDev);

                if (gasleft() < 100000) {
                    payoutIndex = i + 1;
                    return;
                }
            }            
        }
        success = true;
        payoutIndex = 0;
        payoutBalance = 0;
        paused = false;
        lastPayout = now;
        return;
    }   
    
     
    function balanceOf(address owner) public view returns (uint256) {
        Developer memory dev = developers[owner];
        return dev.comission;
    }
    
    
     
    function transferFrom(address from, address to, uint64 value) public comissionLimit(value) whenNotPaused returns (bool)    {
                
        Developer storage devRequester = developers[from];
        require(devRequester.comission > 0, "The developer receiver must exist");
        
        require(value <= balanceOf(from), "There is no enough balance to perform this operation");
        require(value <= _allowed[from][msg.sender], "Trader is not allowed to transact to this limit");

        Developer storage devReciever = developers[to];
        if (devReciever.account == address(0)) {
            Developer memory dev = Developer(to, 0, false);
            developers[to] = dev;
            developerAccounts.push(to);
        }
        
        devRequester.comission = devRequester.comission.sub(value);
        devReciever.comission = devReciever.comission.add(value);

        _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);
        
        emit Transfer(from, to, value);
        return true;
    }

     
    function transfer(address to, uint64 value) public comissionLimit(value) whenNotPaused returns (bool) {
        require(value <= balanceOf(msg.sender), "Spender does not have enough balance");
        require(to != address(0), "Invalid new owner address");
             
        Developer storage devRequester = developers[msg.sender];
        
        require(devRequester.comission >= value, "The developer requester must have comission balance in order to sell her commission");
        
        Developer storage devReciever = developers[to];
        if (devReciever.account == address(0)) {
            Developer memory dev = Developer(to, 0, false);
            developers[to] = dev;
            developerAccounts.push(to);
        }
        
        devRequester.comission = devRequester.comission.sub(value);
        devReciever.comission = devReciever.comission.add(value);
        
        emit Transfer(msg.sender, to, value);
        return true;
    }
    
     
    function approve(address spender, uint64 value) public comissionLimit(value) returns (bool) {
        require(spender != address(0), "Invalid spender");
    
        _allowed[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

     
    function allowance(address owner, address spender) public view returns (uint256)    {
        return _allowed[owner][spender];
    }


     
    function increaseAllowance(address spender, uint64 addedValue) public comissionLimit(addedValue) returns (bool)    {
        require(spender != address(0), "Invalid spender");
        
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }
    

     
    function decreaseAllowance(address spender, uint256 subtractedValue) public comissionLimit(subtractedValue) returns (bool)    {
        require(spender != address(0), "Invalid spender");
        
        _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
        return true;
    }

}
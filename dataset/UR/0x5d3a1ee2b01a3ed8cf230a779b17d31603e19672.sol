 

pragma solidity ^0.4.24;
 
 
 
 
 
library SafeMath {
    
     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
         
         
         
        if (a == 0) {
          return 0;
        }
        
        c = a * b;
        assert(c / a == b);
        return c;
    }
    
     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
     
     
     
        return a / b;
    }
    
     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;   
    }
    
     
    function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
        c = a + b;
        assert(c >= a);
        return c;
    }
}


contract ERC20 {
 
     
    function totalSupply() public constant returns (uint256);

     
    function balanceOf(address who) public view returns (uint256);
    
     
    function transfer(address to, uint256 value) public returns (bool);
    
     
    function transferFrom(address from, address to, uint256 value) public returns (bool);

     
     
     
    function approve(address spender, uint256 value) public returns (bool);

     
    function allowance(address owner, address spender) public view returns (uint256);
 
     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner,address indexed spender,uint256 value);
 
}

 
 
 
contract ColorCoin is ERC20 {

     
    struct accountData {
      uint256 init_balance;
      uint256 balance;
      uint256 unlockTime1;
      uint256 unlockTime2;
      uint256 unlockTime3;
      uint256 unlockTime4;
      uint256 unlockTime5;

      uint256 unlockPercent1;
      uint256 unlockPercent2;
      uint256 unlockPercent3;
      uint256 unlockPercent4;
      uint256 unlockPercent5;
    }
    
    using SafeMath for uint256;

    mapping (address => mapping (address => uint256)) private allowed;
    
    mapping(address => accountData) private accounts;
    
    mapping(address => bool) private lockedAddresses;
    
    address private admin;
    
    address private founder;
    
    bool public isTransferable = false;
    
    string public name;
    
    string public symbol;
    
    uint256 public __totalSupply;
    
    uint8 public decimals;
    
    constructor(string _name, string _symbol, uint256 _totalSupply, uint8 _decimals, address _founder, address _admin) public {
        name = _name;
        symbol = _symbol;
        __totalSupply = _totalSupply;
        decimals = _decimals;
        admin = _admin;
        founder = _founder;
        accounts[founder].init_balance = __totalSupply;
        accounts[founder].balance = __totalSupply;
        emit Transfer(0x0, founder, __totalSupply);
    }
    
     
    modifier onlyAdmin {
        require(admin == msg.sender);
        _;
    }
    
     
    modifier onlyFounder {
        require(founder == msg.sender);
        _;
    }
    
     
    modifier transferable {
        require(isTransferable);
        _;
    }
    
     
    modifier notLocked {
        require(!lockedAddresses[msg.sender]);
        _;
    }
    
     
    function totalSupply() public constant returns (uint256) {
        return __totalSupply;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return accounts[_owner].balance;
    }
        
     
    function transfer(address _to, uint256 _value) transferable notLocked public returns (bool) {
        require(_to != address(0));
        require(_value <= accounts[msg.sender].balance);

        if (!checkTime(msg.sender, _value)) return false;

        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(_value);
        accounts[_to].balance = accounts[_to].balance.add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) transferable notLocked public returns (bool) {
        require(_to != address(0));
        require(_value <= accounts[_from].balance);
        require(_value <= allowed[_from][msg.sender]);
        require(!lockedAddresses[_from]);

        if (!checkTime(_from, _value)) return false;

        accounts[_from].balance = accounts[_from].balance.sub(_value);
        accounts[_to].balance = accounts[_to].balance.add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }
    
     
    function approve(address _spender, uint256 _value) transferable notLocked public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }
    
     
    function allowance(address _owner, address _spender) public view returns (uint256) {
        return allowed[_owner][_spender];
    }

     
    function distribute(address _to, uint256 _value) onlyFounder public returns (bool) {
        require(_to != address(0));
        require(_value <= accounts[msg.sender].balance);
        
        accounts[msg.sender].balance = accounts[msg.sender].balance.sub(_value);
        accounts[_to].balance = accounts[_to].balance.add(_value);
        accounts[_to].init_balance = accounts[_to].init_balance.add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function changeFounder(address who) onlyFounder public {   
        founder = who;
    }

     
    function getFounder() onlyFounder public view returns (address) {
        return founder;
    }

     
    function changeAdmin(address who) onlyAdmin public {
        admin = who;
    }

     
    function getAdmin() onlyAdmin public view returns (address) {
        return admin;
    }

    
     
    function lock(address who) onlyAdmin public {
        
        lockedAddresses[who] = true;
    }

     
    function unlock(address who) onlyAdmin public {
        
        lockedAddresses[who] = false;
    }
    
     
    function isLocked(address who) public view returns(bool) {
        
        return lockedAddresses[who];
    }

     
    function enableTransfer() onlyAdmin public {
        
        isTransferable = true;
    }
    
     
    function disableTransfer() onlyAdmin public {
        
        isTransferable = false;
    }

     
    function checkTime(address who, uint256 _value) public view returns (bool) {
        uint256 total_percent;
        uint256 total_vol;

        total_vol = accounts[who].init_balance.sub(accounts[who].balance);
        total_vol = total_vol.add(_value);

        if (accounts[who].unlockTime1 > now) {
           return false;
        } else if (accounts[who].unlockTime2 > now) {
           total_percent = accounts[who].unlockPercent1;

           if (accounts[who].init_balance.mul(total_percent) < total_vol.mul(100)) 
             return false;
        } else if (accounts[who].unlockTime3 > now) {
           total_percent = accounts[who].unlockPercent1;
           total_percent = total_percent.add(accounts[who].unlockPercent2);

           if (accounts[who].init_balance.mul(total_percent) < total_vol.mul(100)) 
             return false;

        } else if (accounts[who].unlockTime4 > now) {
           total_percent = accounts[who].unlockPercent1;
           total_percent = total_percent.add(accounts[who].unlockPercent2);
           total_percent = total_percent.add(accounts[who].unlockPercent3);

           if (accounts[who].init_balance.mul(total_percent) < total_vol.mul(100)) 
             return false;
        } else if (accounts[who].unlockTime5 > now) {
           total_percent = accounts[who].unlockPercent1;
           total_percent = total_percent.add(accounts[who].unlockPercent2);
           total_percent = total_percent.add(accounts[who].unlockPercent3);
           total_percent = total_percent.add(accounts[who].unlockPercent4);

           if (accounts[who].init_balance.mul(total_percent) < total_vol.mul(100)) 
             return false;
        } else { 
           total_percent = accounts[who].unlockPercent1;
           total_percent = total_percent.add(accounts[who].unlockPercent2);
           total_percent = total_percent.add(accounts[who].unlockPercent3);
           total_percent = total_percent.add(accounts[who].unlockPercent4);
           total_percent = total_percent.add(accounts[who].unlockPercent5);

           if (accounts[who].init_balance.mul(total_percent) < total_vol.mul(100)) 
             return false;
        }
        
        return true; 
       
    }

     
    function setTime1(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockTime1 = value;
        return true;
    }

    function getTime1(address who) public view returns (uint256) {
        return accounts[who].unlockTime1;
    }

     
    function setTime2(address who, uint256 value) onlyFounder public returns (bool) {

        accounts[who].unlockTime2 = value;
        return true;
    }

    function getTime2(address who) public view returns (uint256) {
        return accounts[who].unlockTime2;
    }

     
    function setTime3(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockTime3 = value;
        return true;
    }

    function getTime3(address who) public view returns (uint256) {
        return accounts[who].unlockTime3;
    }

     
    function setTime4(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockTime4 = value;
        return true;
    }

    function getTime4(address who) public view returns (uint256) {
        return accounts[who].unlockTime4;
    }

     
    function setTime5(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockTime5 = value;
        return true;
    }

    function getTime5(address who) public view returns (uint256) {
        return accounts[who].unlockTime5;
    }

     
    function setPercent1(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockPercent1 = value;
        return true;
    }

    function getPercent1(address who) public view returns (uint256) {
        return accounts[who].unlockPercent1;
    }

     
    function setPercent2(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockPercent2 = value;
        return true;
    }

    function getPercent2(address who) public view returns (uint256) {
        return accounts[who].unlockPercent2;
    }

     
    function setPercent3(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockPercent3 = value;
        return true;
    }

    function getPercent3(address who) public view returns (uint256) {
        return accounts[who].unlockPercent3;
    }

     
    function setPercent4(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockPercent4 = value;
        return true;
    }

    function getPercent4(address who) public view returns (uint256) {
        return accounts[who].unlockPercent4;
    }

     
    function setPercent5(address who, uint256 value) onlyFounder public returns (bool) {
        accounts[who].unlockPercent5 = value;
        return true;
    }

    function getPercent5(address who) public view returns (uint256) {
        return accounts[who].unlockPercent5;
    }

     
    function getInitBalance(address _owner) public view returns (uint256) {
        return accounts[_owner].init_balance;
    }
}
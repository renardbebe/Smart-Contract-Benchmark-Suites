 

pragma solidity ^0.4.24;

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 


 
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
        assert(a == b * c + a % b);  

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

 
    constructor() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }
}



 
contract StandardToken {

    mapping (address => mapping (address => uint256)) internal allowed;
    using SafeMath for uint256;
    uint256 public totalSupply;
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    mapping(address => uint256) balances;
    
     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);
        require(balances[msg.sender] >= _value && balances[_to].add(_value) >= balances[_to]);

    
         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public constant returns (uint256 balance) {
        return balances[_owner];
    }
    
     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
     
     

        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);
    
        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }       

     
    function approve(address _spender, uint256 _value) public returns (bool) {

     
     
     
     
        require((_value == 0) || (allowed[msg.sender][_spender] == 0));
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public constant returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}

 
contract Token0xC is StandardToken, Ownable {
    using SafeMath for uint256;

     
    string  public constant name = "0xC";
    string  public constant symbol = "0xC";
    uint8   public constant decimals = 18;

     
    uint256 public startDate1;
    uint256 public endDate1;
    uint256 public rate1;
    
     
    uint256 public startDate2;
    uint256 public endDate2;
    uint256 public rate2;
    
     
    uint256 public startDate3;
    uint256 public endDate3;
    uint256 public rate3;

     
    uint256 BaseTimestamp = 1534377600;
    
     
    uint256 public dailyCap;
    uint256 public saleCap;
    uint256 public LastbetDay;
    uint256 public LeftDailyCap;

     
    address public tokenWallet ;

     
    address public fundWallet ;

     
    event TokenPurchase(address indexed purchaser, uint256 value, uint256 amount);
    event TransferToken(address indexed buyer, uint256 amount);

     
    modifier uninitialized() {
        require(tokenWallet == 0x0);
        require(fundWallet == 0x0);
        _;
    }

    constructor() public {}
     
     
    function () public payable {
        buyTokens(msg.sender, msg.value);
    }

     
    function initialize(address _tokenWallet, address _fundWallet, uint256 _start1, uint256 _end1,
                         uint256 _dailyCap, uint256 _saleCap, uint256 _totalSupply) public
                        onlyOwner uninitialized {
        require(_start1 < _end1);
        require(_tokenWallet != 0x0);
        require(_fundWallet != 0x0);
        require(_totalSupply >= _saleCap);

        startDate1 = _start1;
        endDate1 = _end1;
        saleCap = _saleCap;
        dailyCap = _dailyCap;
        tokenWallet = _tokenWallet;
        fundWallet = _fundWallet;
        totalSupply = _totalSupply;

        balances[tokenWallet] = saleCap;
        balances[0xb1] = _totalSupply.sub(saleCap);
    }

     
    function setPeriod(uint256 period, uint256 _start, uint256 _end) public onlyOwner {
        require(_end > _start);
        if (period == 1) {
            startDate1 = _start;
            endDate1 = _end;
        }else if (period == 2) {
            require(_start > endDate1);
            startDate2 = _start;
            endDate2 = _end;
        }else if (period == 3) {
            require(_start > endDate2);
            startDate3 = _start;
            endDate3 = _end;      
        }
    }

     
    function setPeriodRate(uint256 _period, uint256 _rate) public onlyOwner {
        if (_period == 1) {
           rate1 = _rate;
        }else if (_period == 2) {
            rate2 = _rate;
        }else if (_period == 3) {
            rate3 = _rate;
        }
    }

     
    function transferToken(address _to, uint256 amount) public onlyOwner {
        require(saleCap >= amount,' Not Enough' );
        require(_to != address(0));
        require(_to != tokenWallet);
        require(amount <= balances[tokenWallet]);

        saleCap = saleCap.sub(amount);
         
        balances[tokenWallet] = balances[tokenWallet].sub(amount);
        balances[_to] = balances[_to].add(amount);
        emit TransferToken(_to, amount);
        emit Transfer(tokenWallet, _to, amount);
    }

    function setDailyCap(uint256 _dailyCap) public onlyOwner{
        dailyCap = _dailyCap;
    }

     
    function setSaleCap(uint256 _saleCap) public onlyOwner {
        require(balances[0xb1].add(balances[tokenWallet]).sub(_saleCap) >= 0);
        uint256 amount = 0;
         
        if (balances[tokenWallet] > _saleCap) {
            amount = balances[tokenWallet].sub(_saleCap);
            balances[0xb1] = balances[0xb1].add(amount);
        } else {
            amount = _saleCap.sub(balances[tokenWallet]);
            balances[0xb1] = balances[0xb1].sub(amount);
        }
        balances[tokenWallet] = _saleCap;
        saleCap = _saleCap;
    }

     
    function getBonusByTime() public constant returns (uint256) {
        if (now < startDate1) {
            return 0;
        } else if (endDate1 > now && now > startDate1) {
            return rate1;
        } else if (endDate2 > now && now > startDate2) {
            return rate2;
        } else if (endDate3 > now && now > startDate3) {
            return rate3;
        } else {
            return 0;
        }
    }

     
    function finalize() public onlyOwner {
        require(!saleActive());

         
        balances[tokenWallet] = balances[tokenWallet].add(balances[0xb1]);
        balances[0xb1] = 0;
    }
    
     
    function DateConverter(uint256 ts) public view returns(uint256 currentDayWithoutTime){
        uint256 dayInterval = ts.sub(BaseTimestamp);
        uint256 dayCount = dayInterval.div(86400);
        return BaseTimestamp.add(dayCount.mul(86400));
    }
    
     
    function saleActive() public constant returns (bool) {
        return (
            (now >= startDate1 &&
                now < endDate1 && saleCap > 0) ||
            (now >= startDate2 &&
                now < endDate2 && saleCap > 0) ||
            (now >= startDate3 &&
                now < endDate3 && saleCap > 0)
                );
    }
    
     
    function buyTokens(address sender, uint256 value) internal {
         
        require(saleActive());
        
         
        require(value >= 0.0001 ether);
        require(sender != tokenWallet);
        
        if(DateConverter(now) > LastbetDay )
        {
            LastbetDay = DateConverter(now);
            LeftDailyCap = dailyCap;
        }

         
        uint256 bonus = getBonusByTime();
        
        uint256 amount = value.mul(bonus);
        
         
        require(LeftDailyCap >= amount, "cap not enough");
        require(balances[tokenWallet] >= amount);
        
        LeftDailyCap = LeftDailyCap.sub(amount);

         
        balances[tokenWallet] = balances[tokenWallet].sub(amount);
        balances[sender] = balances[sender].add(amount);
        emit TokenPurchase(sender, value, amount);
        emit Transfer(tokenWallet, sender, amount);
        
        saleCap = saleCap.sub(amount);

         
        fundWallet.transfer(msg.value);
    }
}
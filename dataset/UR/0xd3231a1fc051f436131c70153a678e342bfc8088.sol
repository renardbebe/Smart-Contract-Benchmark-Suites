 

 

pragma solidity 0.4.19;

 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ERC20 {

    function totalSupply()public view returns (uint total_Supply);
    function balanceOf(address who)public view returns (uint256);
    function allowance(address owner, address spender)public view returns (uint);
    function transferFrom(address from, address to, uint value)public returns (bool ok);
    function approve(address spender, uint value)public returns (bool ok);
    function transfer(address to, uint value)public returns (bool ok);

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

}

contract FiatContract
{
    function USD(uint _id) constant returns (uint256);
}

contract TestFiatContract
{
    function USD(uint) constant returns (uint256)
    {
        return 12305041990000;
    }
}


contract SocialActivityToken is ERC20
{ 
    using SafeMath for uint256;

    FiatContract price = FiatContract(new TestFiatContract());  

     
    string public constant name = "Social Activity Token";
     
    string public constant symbol = "SAT";
    uint8 public constant decimals = 8;
    uint public _totalsupply = 1000000000 * (uint256(10) ** decimals);  
    address public owner;
    bool stopped = false;
    uint256 public startdate;
    uint256 ico_first;
    uint256 ico_second;
    uint256 ico_third;
    uint256 ico_fourth;
    address central_account;
    mapping(address => uint) balances;
    mapping(address => mapping(address => uint)) allowed;

    
    enum Stages {
        NOTSTARTED,
        ICO,
        PAUSED,
        ENDED
    }

    Stages public stage;
    
    modifier atStage(Stages _stage) {
        if (stage != _stage)
             
            revert();
        _;
    }
    
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert();
        }
        _;
    }

    modifier onlycentralAccount {
        require(msg.sender == central_account);
        _;
    }

    function SocialActivityToken() public
    {
        owner = msg.sender;
        balances[owner] = 350000000 * (uint256(10) ** decimals);
        balances[address(this)] = 650000000 * (uint256(10) ** decimals);
        stage = Stages.NOTSTARTED;
        Transfer(0, owner, balances[owner]);
        Transfer(0, address(this), balances[address(this)]);
    }
    
    function () public payable atStage(Stages.ICO)
    {
        require(msg.value >= 1 finney);  
        require(!stopped && msg.sender != owner);

        uint256 ethCent = price.USD(0);  
        uint256 tokPrice = ethCent.mul(14);  
        
        tokPrice = tokPrice.div(10 ** 8);  
        uint256 no_of_tokens = msg.value.div(tokPrice);
        
        uint256 bonus_token = 0;
        
         
        if (now < ico_first)
        {
            if (no_of_tokens >=  2000 * (uint256(10)**decimals) &&
                no_of_tokens <= 19999 * (uint256(10)**decimals))
            {
                bonus_token = no_of_tokens.mul(50).div(100);  
            }
            else if (no_of_tokens >   19999 * (uint256(10)**decimals) &&
                     no_of_tokens <= 149999 * (uint256(10)**decimals))
            {
                bonus_token = no_of_tokens.mul(55).div(100);  
            }
            else if (no_of_tokens > 149999 * (uint256(10)**decimals))
            {
                bonus_token = no_of_tokens.mul(60).div(100);  
            }
            else
            {
                bonus_token = no_of_tokens.mul(45).div(100);  
            }
        }
        else if (now >= ico_first && now < ico_second)
        {
            if (no_of_tokens >=  2000 * (uint256(10)**decimals) &&
                no_of_tokens <= 19999 * (uint256(10)**decimals))
            {
                bonus_token = no_of_tokens.mul(40).div(100);  
            }
            else if (no_of_tokens >   19999 * (uint256(10)**decimals) &&
                     no_of_tokens <= 149999 * (uint256(10)**decimals))
            {
                bonus_token = no_of_tokens.mul(45).div(100);  
            }
            else if (no_of_tokens >  149999 * (uint256(10)**decimals))
            {
                bonus_token = no_of_tokens.mul(50).div(100);  
            }
            else
            {
                bonus_token = no_of_tokens.mul(35).div(100);  
            }
        }
        else if (now >= ico_second && now < ico_third)
        {
            if (no_of_tokens >=  2000 * (uint256(10)**decimals) &&
                no_of_tokens <= 19999 * (uint256(10)**decimals))
            {
                bonus_token = no_of_tokens.mul(30).div(100);  
            }
            else if (no_of_tokens >   19999 * (uint256(10)**decimals) &&
                     no_of_tokens <= 149999 * (uint256(10)**decimals))
            {
                bonus_token = no_of_tokens.mul(35).div(100);  
            }
            else if (no_of_tokens >  149999 * (uint256(10)**decimals))
            {
                bonus_token = no_of_tokens.mul(40).div(100);  
            }
            else
            {
                bonus_token = no_of_tokens.mul(25).div(100);  
            }
        }
        else if (now >= ico_third && now < ico_fourth)
        {
            if (no_of_tokens >=  2000 * (uint256(10)**decimals) &&
                no_of_tokens <= 19999 * (uint256(10)**decimals))
            {
                bonus_token = no_of_tokens.mul(20).div(100);  
            }
            else if (no_of_tokens >   19999 * (uint256(10)**decimals) &&
                     no_of_tokens <= 149999 * (uint256(10)**decimals))
            {
                bonus_token = no_of_tokens.mul(25).div(100);  
            }
            else if (no_of_tokens >  149999 * (uint256(10)**decimals))
            {
                bonus_token = no_of_tokens.mul(30).div(100);  
            }
            else
            {
                bonus_token = no_of_tokens.mul(15).div(100);  
            }
        }
        
        uint256 total_token = no_of_tokens + bonus_token;
        this.transfer(msg.sender, total_token);
    }
    
    function start_ICO() public onlyOwner atStage(Stages.NOTSTARTED) {

        stage = Stages.ICO;
        stopped = false;
        startdate = now;
        ico_first = now + 5 minutes;  
        ico_second = ico_first + 5 minutes;  
        ico_third = ico_second + 5 minutes;  
        ico_fourth = ico_third + 5 minutes;  
    
    }
    
     
    function StopICO() external onlyOwner atStage(Stages.ICO) {
    
        stopped = true;
        stage = Stages.PAUSED;
    
    }

     
    function releaseICO() external onlyOwner atStage(Stages.PAUSED) {
    
        stopped = false;
        stage = Stages.ICO;
    
    }
    
    function end_ICO() external onlyOwner atStage(Stages.ICO) {
    
        require(now > ico_fourth);
        stage = Stages.ENDED;
   
    }
    
    function burn(uint256 _amount) external onlyOwner
    {
        require(_amount <= balances[address(this)]);
        
        _totalsupply = _totalsupply.sub(_amount);
        balances[address(this)] = balances[address(this)].sub(_amount);
        balances[0x0] = balances[0x0].add(_amount);
        Transfer(address(this), 0x0, _amount);
    }
     
    function set_centralAccount(address central_Acccount) external onlyOwner {
    
        central_account = central_Acccount;
    
    }



     
    function totalSupply() public view returns (uint256 total_Supply) {
    
        total_Supply = _totalsupply;
    
    }
    
     
    function balanceOf(address _owner)public view returns (uint256 balance) {
    
        return balances[_owner];
    
    }
    
     
     
     
     
     
     
    function transferFrom( address _from, address _to, uint256 _amount )public returns (bool success) {
    
        require( _to != 0x0);
    
        balances[_from] = balances[_from].sub(_amount);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
    
        Transfer(_from, _to, _amount);
    
        return true;
    }
    
     
     
    function approve(address _spender, uint256 _amount)public returns (bool success) {
        require(_amount == 0 || allowed[msg.sender][_spender] == 0);
        require( _spender != 0x0);
    
        allowed[msg.sender][_spender] = _amount;
    
        Approval(msg.sender, _spender, _amount);
    
        return true;
    }
  
    function allowance(address _owner, address _spender)public view returns (uint256 remaining) {
    
        require( _owner != 0x0 && _spender !=0x0);
    
        return allowed[_owner][_spender];
   
   }

     
    function transfer(address _to, uint256 _amount)public returns (bool success) {
    
        require( _to != 0x0);
        
        balances[msg.sender] = balances[msg.sender].sub(_amount);
        balances[_to] = balances[_to].add(_amount);
    
        Transfer(msg.sender, _to, _amount);
    
        return true;
    }
    
    function transferby(address _from,address _to,uint256 _amount) external onlycentralAccount returns(bool success) {
    
        require( _to != 0x0);
        
         
        require(_from == 0x0 || _from == address(this));
        
        balances[_from] = (balances[_from]).sub(_amount);
        balances[_to] = (balances[_to]).add(_amount);
        if (_from == 0x0)
        {
            _totalsupply = _totalsupply.add(_amount);
        }
    
        Transfer(_from, _to, _amount);
    
        return true;
    }

     
    function transferOwnership(address newOwner)public onlyOwner {

        balances[newOwner] = balances[newOwner].add(balances[owner]);
        balances[owner] = 0;
        owner = newOwner;
    
    }

    function drain() external onlyOwner {
    
        owner.transfer(this.balance);
    
    }
    
}
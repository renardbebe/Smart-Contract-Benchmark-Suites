 

 

pragma solidity ^0.4.20;

library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a);
        return c;
    }
}


 
contract ERC20Basic {
    uint256 public totalSupply;
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract BasicToken is ERC20Basic {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[msg.sender]);

         
        balances[msg.sender] = balances[msg.sender].sub(_value);
        balances[_to] = balances[_to].add(_value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }

}

 
contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 
library SafeERC20 {
    function safeTransfer(ERC20Basic token, address to, uint256 value) internal {
        assert(token.transfer(to, value));
    }

    function safeTransferFrom(ERC20 token, address from, address to, uint256 value) internal {
        assert(token.transferFrom(from, to, value));
    }

    function safeApprove(ERC20 token, address spender, uint256 value) internal {
        assert(token.approve(spender, value));
    }
}


 
contract TokenTimelock {
    using SafeERC20 for ERC20Basic;

     
    ERC20Basic public token;

     
    address public beneficiary;

     
    uint64 public releaseTime;

    function TokenTimelock(ERC20Basic _token, address _beneficiary, uint64 _releaseTime) public {
        require(_releaseTime > uint64(block.timestamp));
        token = _token;
        beneficiary = _beneficiary;
        releaseTime = _releaseTime;
    }

     
    function release() public {
        require(uint64(block.timestamp) >= releaseTime);

        uint256 amount = token.balanceOf(this);
        require(amount > 0);

        token.safeTransfer(beneficiary, amount);
    }
}


 
contract StandardToken is ERC20, BasicToken {

    mapping (address => mapping (address => uint256)) internal allowed;

     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool) {
        require(_to != address(0));
        require(_value <= balances[_from]);
        require(_value <= allowed[_from][msg.sender]);

        balances[_from] = balances[_from].sub(_value);
        balances[_to] = balances[_to].add(_value);
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
        Transfer(_from, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }

     
    function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

}


contract Owned {
    address public owner;
    
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    function Owned() public {
        owner = msg.sender;
    }
    
     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }
}


contract OrguraExchange is StandardToken, Owned {
    string public constant name = "Orgura Exchange";
    string public constant symbol = "OGX";
    uint8 public constant decimals = 18;

     
    uint256 public constant HARD_CAP = 800000000 * 10**uint256(decimals);   

     
    uint256 public constant TOKENS_SALE_HARD_CAP = 400000000 * 10**uint256(decimals);

     
    uint256 public constant BASE_RATE = 7169;


     
     
    uint64 private constant dateSeedSale = 1523145600 + 0 hours;  

     
    uint64 private constant datePreSale = 1524182400 + 0 hours;  

     
    uint64 private constant dateSaleR1 = 1525132800 + 0 hours;  

     
    uint64 private constant dateSaleR2 = 1526342400 + 0 hours;  

     
    uint64 private constant dateSaleR3 = 1527724800 + 0 hours;  

     
    uint64 private constant date14June2018 = 1528934400 + 0 hours;

     
    uint64 private constant date14July2018 = 1531526400;
    
     
    uint256[5] private roundCaps = [
        50000000* 10**uint256(decimals),  
        50000000* 10**uint256(decimals),  
        100000000* 10**uint256(decimals),  
        100000000* 10**uint256(decimals),  
        100000000* 10**uint256(decimals)  
    ];
    uint8[5] private roundDiscountPercentages = [90, 75, 50, 30, 15];


     
    uint64[4] private dateTokensLockedTills = [
        1536883200,  
        1544745600,  
        1557792000,  
        1581638400  
    ];

     
    uint8[4] private lockedTillPercentages = [20, 20, 30, 30];

     
    uint64 private constant dateTeamTokensLockedTill = 1556323200;

     
    bool public tokenSaleClosed = false;

     
    address public timelockContractAddress;

    modifier inProgress {
        require(totalSupply < TOKENS_SALE_HARD_CAP
            && !tokenSaleClosed && now >= dateSeedSale);
        _;
    }

     
    modifier beforeEnd {
        require(!tokenSaleClosed);
        _;
    }

     
    modifier tradingOpen {
         
         
         

         
        require(uint64(block.timestamp) > date14July2018);
        _;
    }

    function OrguraExchange() public {
    }

     
     
    function () public payable {
        purchaseTokens(msg.sender);
    }

     
     
    function purchaseTokens(address _beneficiary) public payable inProgress {
         
        require(msg.value >= 0.01 ether);

        uint256 tokens = computeTokenAmount(msg.value);
        
         
        require(totalSupply.add(tokens) <= TOKENS_SALE_HARD_CAP);
        
        doIssueTokens(_beneficiary, tokens);

         
        owner.transfer(this.balance);
    }

     
     
     
    function issueTokensMulti(address[] _addresses, uint256[] _tokens) public onlyOwner beforeEnd {
        require(_addresses.length == _tokens.length);
        require(_addresses.length <= 100);

        for (uint256 i = 0; i < _tokens.length; i = i.add(1)) {
            doIssueTokens(_addresses[i], _tokens[i]);
        }
    }


     
     
     
    function issueTokens(address _beneficiary, uint256 _tokens) public onlyOwner beforeEnd {
        doIssueTokens(_beneficiary, _tokens);
    }

     
     
     
    function doIssueTokens(address _beneficiary, uint256 _tokens) internal {
        require(_beneficiary != address(0));

         
        totalSupply = totalSupply.add(_tokens);
         
        balances[_beneficiary] = balances[_beneficiary].add(_tokens);

         
        Transfer(address(0), _beneficiary, _tokens);
    }

     
    function price() public view returns (uint256 tokens) {
        return computeTokenAmount(1 ether);
    }

     
     
     
    function computeTokenAmount(uint256 ethAmount) internal view returns (uint256 tokens) {
        uint256 tokenBase = ethAmount.mul(BASE_RATE);
        uint8 roundNum = currentRoundIndex();
        tokens = tokenBase.mul(100)/(100 - (roundDiscountPercentages[roundNum]));
        while(tokens.add(totalSupply) > roundCaps[roundNum] && roundNum < 4){
           roundNum++;
           tokens = tokenBase.mul(100)/(100 - (roundDiscountPercentages[roundNum])); 
        }
    }

     
     
    function currentRoundIndex() internal view returns (uint8 roundNum) {
        roundNum = currentRoundIndexByDate();

         
        while(roundNum < 4 && totalSupply > roundCaps[roundNum]) {
            roundNum++;
        }
    }

     
     
    function currentRoundIndexByDate() internal view returns (uint8 roundNum) {
        require(now <= date14June2018); 
        if(now > dateSaleR3) return 4;
        if(now > dateSaleR2) return 3;
        if(now > dateSaleR1) return 2;
        if(now > datePreSale) return 1;
        else return 0;
    }

      
    function close() public onlyOwner beforeEnd {

       
        uint256 amount_lockedTokens = 300000000;  
        
        uint256 lockedTokens = amount_lockedTokens* 10**uint256(decimals);  
        
         
        uint256 reservedTokens =  100000000* 10**uint256(decimals);  
        
         
        uint256 sumlockedAndReservedTokens = lockedTokens + reservedTokens;

         
        uint256 fagmentSale = 0* 10**uint256(decimals);  

         
        if(totalSupply.add(sumlockedAndReservedTokens) > HARD_CAP) {

            sumlockedAndReservedTokens = HARD_CAP.sub(totalSupply);

        }

         
        
         
         

        uint256 _total_lockedTokens =0;

        for (uint256 i = 0; i < lockedTillPercentages.length; i = i.add(1)) 
        {
            _total_lockedTokens =0;
            _total_lockedTokens = amount_lockedTokens.mul(lockedTillPercentages[i])* 10**uint256(decimals)/100;
             
            issueLockedTokensCustom( _total_lockedTokens, dateTokensLockedTills[i] );

        }
         


        issueReservedTokens(reservedTokens);
        
        
         
        totalSupply = totalSupply.add(sumlockedAndReservedTokens);
        
         
        tokenSaleClosed = true;

         
        owner.transfer(this.balance);
    }

     
    function issueLockedTokens( uint lockedTokens) internal{
         
        TokenTimelock lockedTeamTokens = new TokenTimelock(this, owner, dateTeamTokensLockedTill);
        timelockContractAddress = address(lockedTeamTokens);
        balances[timelockContractAddress] = balances[timelockContractAddress].add(lockedTokens);
         
        Transfer(address(0), timelockContractAddress, lockedTokens);
        
    }

    function issueLockedTokensCustom( uint lockedTokens , uint64 _dateTokensLockedTill) internal{
         
        TokenTimelock lockedTeamTokens = new TokenTimelock(this, owner, _dateTokensLockedTill);
        timelockContractAddress = address(lockedTeamTokens);
        balances[timelockContractAddress] = balances[timelockContractAddress].add(lockedTokens);
         
        Transfer(address(0), timelockContractAddress, lockedTokens);
        
    }

     
    function issueReservedTokens(uint reservedTokens) internal{
        balances[owner] = reservedTokens;
        Transfer(address(0), owner, reservedTokens);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

     
    function transfer(address _to, uint256 _value) public tradingOpen returns (bool) {
        return super.transfer(_to, _value);
    }

}
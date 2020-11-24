 

pragma solidity ^0.4.18;

 
library SafeMath {
  function Mul (uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }

  function Div (uint256 a, uint256 b) internal pure returns (uint256) {
     
    uint256 c = a / b;
     
    return c;
  }

  function Sub (uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function Add (uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

 
contract Ownable {

	 
  address public owner;

   
  function Ownable() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

}

 
contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract GIZAToken is ERC20, Ownable {

    using SafeMath for uint256;
     
    bytes32 public name;
     
    bytes32 public symbol;
     
    uint8 public decimals;   
     
    bool public locked;
	 
	address public founder;
	 
	address public team;
	 
	uint256 public start;
	
     
    mapping(address => uint256 ) balances;
     
    mapping(address => mapping(address => uint256)) allowed;

    event Burn(address indexed burner, uint indexed value);  

     
    function GIZAToken(address _founder, address _team) public {
		require( _founder != address(0) && _team != address(0) );
         
         
        name = "GIZA Token";
         
        symbol = "GIZA";
         
        decimals = 18;       
         
        totalSupply = 368e23;  
         
        locked = true;
		 
		founder = _founder;
		team = _team;
		balances[msg.sender] = totalSupply;
		start = 0;
    }
      
	function startNow() external onlyOwner {
		start = now;
	}
	  
     
    modifier onlyPayloadSize(uint256 size) {
       require(msg.data.length >= size + 4);
       _;
    }

    modifier onlyUnlocked() { 
      require (!locked); 
      _; 
    }
	
    modifier ifNotFroze() { 
		if ( 
		  (msg.sender == founder || msg.sender == team) && 
		  (start == 0 || now < (start + 80 days) ) ) revert();
		_;
    }
    
     
    function unlockTransfer() external onlyOwner{
      locked = false;
    }

     
    function balanceOf(address _owner) public view returns (uint256 _value){
        return balances[_owner];
    }

     
    function transfer(address _to, uint256 _value) onlyPayloadSize(2 * 32) onlyUnlocked ifNotFroze public returns(bool _success) {
        require( _to != address(0) );
        if((balances[msg.sender] > _value) && _value > 0){
			balances[msg.sender] = balances[msg.sender].Sub(_value);
			balances[_to] = balances[_to].Add(_value);
			Transfer(msg.sender, _to, _value);
			return true;
        }
        else{
            return false;
        }
    }

     
    function transferFrom(address _from, address _to, uint256 _value) onlyPayloadSize(3 * 32) onlyUnlocked ifNotFroze public returns (bool success){
        require( _to != address(0) && (_from != address(0)));
        if((_value > 0)
           && (allowed[_from][msg.sender] > _value )){
            balances[_from] = balances[_from].Sub(_value);
            balances[_to] = balances[_to].Add(_value);
            allowed[_from][msg.sender] = allowed[_from][msg.sender].Sub(_value);
            Transfer(_from, _to, _value);
            return true;
        }
        else{
            return false;
        }
    }

     
    function allowance(address _owner, address _spender) public view returns (uint256){
        return allowed[_owner][_spender];
    }

     
    function approve(address _spender, uint256 _value) public returns (bool){
        if( (_value > 0) && (_spender != address(0)) && (balances[msg.sender] >= _value)){
            allowed[msg.sender][_spender] = _value;
            Approval(msg.sender, _spender, _value);
            return true;
        }
        else{
            return false;
        }
    }
    
     
    function burn(uint _value) public onlyOwner {
        require(_value > 0);
        address burner = msg.sender;
        balances[burner] = balances[burner].Sub(_value);
        totalSupply = totalSupply.Sub(_value);
        Burn(burner, _value);
    }

}

contract Crowdsale is Ownable {
    
    using SafeMath for uint256;
    GIZAToken token;
    address public token_address;
    address public owner;
    address founder;
    address team;
    address multisig;
    bool started = false;
     
    uint256 public dollarsForEther;
     
    uint256 constant DURATION_PRE_ICO = 30;
    uint256 startBlock = 0;  
    uint256 tokensBought = 0;  
    uint256 totalRaisedEth = 0;  

    uint256 constant MAX_TOKENS_FIRST_7_DAYS_PRE_ICO  = 11000000 * 1 ether;  
	uint256 constant MAX_TOKENS_PRE_ICO    				    = 14850000 * 1 ether;  
    uint256 constant MAX_TOKENS_FIRST_5_DAYS_ICO        = 3850000 * 1 ether;    
    uint256 constant MAX_TOKENS_FIRST_10_DAYS_ICO      	= 10725000 * 1 ether;  
    uint256 constant MAX_BOUNTY      	                			= 1390000 * 1 ether;
    uint256 bountySent = 0;
    enum CrowdsaleType { PreICO, ICO }
    CrowdsaleType etype = CrowdsaleType.PreICO;
    
    
    function Crowdsale(address _founder, address _team, address _multisig) public {
        require(_founder != address(0) && _team != address(0) && _multisig != address(0));
        owner = msg.sender;
        team = _team;
        multisig = _multisig;
        founder = _founder;
        token = new GIZAToken(_founder, _team);
        token_address = address(token);
    }
    
    modifier isStarted() {
        require (started == true);
        _;
    }
    
     
    function setDollarForOneEtherRate(uint256 _dollars) public onlyOwner {
        dollarsForEther = _dollars;
    }
    
    function sendBounty(address _to, uint256 _amount) public onlyOwner returns(bool){
        require(_amount != 0 && _to != address(0));
        token.unlockTransfer();
        uint256 totalToSend = _amount.Mul(1 ether);
        require(bountySent.Add(totalToSend) < MAX_BOUNTY);
        if ( transferTokens(_to, totalToSend) ){
                bountySent = bountySent.Add(totalToSend);
                return true;
        }else
            return false;        
    }
    
    function sendTokens(address _to, uint256 _amount) public onlyOwner returns(bool){
        require(_amount != 0 && _to != address(0));
        token.unlockTransfer();
        return transferTokens(_to, _amount.Mul(1 ether));
    } 
  
     
    function startPreICO(uint256 _dollarForOneEtherRate) public onlyOwner {
        require(startBlock == 0 && _dollarForOneEtherRate > 0);
         
        startBlock = now;
         
        etype = CrowdsaleType.PreICO;
        started = true;
        dollarsForEther = _dollarForOneEtherRate;
        token.startNow();
        token.unlockTransfer();
    }
	
	 
	function endPreICO() public onlyOwner {
		started = false;
	}
  
     
    function startICO(uint256 _dollarForOneEtherRate) public onlyOwner{
         
        require( startBlock != 0 && now > startBlock.Add(DURATION_PRE_ICO) );
        startBlock = now;
         
        etype = CrowdsaleType.ICO;
        started = true;
        dollarsForEther = _dollarForOneEtherRate;
    }
    
     
    function getCurrentTokenPriceInCents() public view returns(uint256){
        require(startBlock != 0);
        uint256 _day = (now - startBlock).Div(1 days);
         
        if (etype == CrowdsaleType.PreICO){
            require(_day <= DURATION_PRE_ICO && tokensBought < MAX_TOKENS_PRE_ICO);
            if (_day >= 0 && _day <= 7 && tokensBought < MAX_TOKENS_FIRST_7_DAYS_PRE_ICO)
                return 20;  
			else
                return 30;  
         
        } else {
            if (_day >= 0 && _day <= 5 && tokensBought < MAX_TOKENS_FIRST_5_DAYS_ICO)
                return 60;  
            else if (_day > 5 && _day <= 10 && tokensBought < MAX_TOKENS_FIRST_10_DAYS_ICO)
                return 80;  
            else
                return 100;  
        }        
    }
    
     
    function calcTokensToSend(uint256 _value) internal view returns (uint256){
        require (_value > 0);
        
         
        uint256 currentTokenPrice = getCurrentTokenPriceInCents();
        
         
         
         
        uint256 valueInDollars = _value.Mul(dollarsForEther).Div(10**16);
        uint256 tokensToSend = valueInDollars.Div(currentTokenPrice);
        
         
        uint8 bonusPercent = 0;
        _value = _value.Div(1 ether).Mul(dollarsForEther);
        if ( _value >= 35000 ){
            bonusPercent = 10;
        }else if ( _value >= 20000 ){
            bonusPercent = 7;
        }else if ( _value >= 10000 ){
            bonusPercent = 5;
        }
         
        if (bonusPercent > 0) tokensToSend = tokensToSend.Add(tokensToSend.Div(100).Mul(bonusPercent));
        
        return tokensToSend;
    }    

     
    function forwardFunds(uint256 _value) internal {
        multisig.transfer(_value);
    }

     
    function transferTokens(address _to, uint256 _tokensToSend) internal returns(bool){
        uint256 tot = _tokensToSend.Mul(1222).Div(8778);  
        uint256 tokensForTeam = tot.Mul(4443).Div(1e4); 
        uint256 tokensForFounder = tot.Sub(tokensForTeam); 
        uint256 totalToSend = _tokensToSend.Add(tokensForFounder).Add(tokensForTeam);
        if (token.balanceOf(this) >= totalToSend && 
            token.transfer(_to, _tokensToSend) == true){
                token.transfer(founder, tokensForFounder);
                token.transfer(team, tokensForTeam);
                tokensBought = tokensBought.Add(totalToSend);
                return true;
        }else
            return false;
    }

    function buyTokens(address _beneficiary) public isStarted payable {
        require(_beneficiary != address(0) &&  msg.value != 0 );
        uint256 tokensToSend = calcTokensToSend(msg.value);
        tokensToSend = tokensToSend.Mul(1 ether);
        
         
        if (etype == CrowdsaleType.PreICO){
            require(tokensBought.Add(tokensToSend) < MAX_TOKENS_PRE_ICO);
        }      
        
        if (!transferTokens(_beneficiary, tokensToSend)) revert();
        totalRaisedEth = totalRaisedEth.Add( (msg.value).Div(1 ether) );
        forwardFunds(msg.value);
    }

     
    function () public payable {
        buyTokens(msg.sender);
    }
    
     
    function burnTokens() public onlyOwner {
        token.burn( token.balanceOf(this) );
        started = false;
    }
    
     
    function kill() public onlyOwner{
        selfdestruct(multisig);   
    }
}
 

pragma solidity 0.4.25;


 
interface IERC20 {
  function totalSupply() external view returns (uint256);

  function balanceOf(address _who) external view returns (uint256);

  function allowance(address _owner, address _spender) external view returns (uint256);

  function transfer(address _to, uint256 _value) external returns (bool);

  function approve(address _spender, uint256 _value) external returns (bool);

  function transferFrom(address _from, address _to, uint256 _value) external returns (bool);

  event Transfer(
    address indexed from,
    address indexed to,
    uint256 value
  );

  event Approval(
    address indexed owner,
    address indexed spender,
    uint256 value
  );
}


 
library SafeMath {

     
    function mul(uint256 _a, uint256 _b) internal pure returns (uint256) {
         
         
         
        if (_a == 0) {
            return 0;
        }

        uint256 c = _a * _b;
        require(c / _a == _b,"Math error");

        return c;
    }

     
    function div(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b > 0,"Math error");  
        uint256 c = _a / _b;
         

        return c;
    }

     
    function sub(uint256 _a, uint256 _b) internal pure returns (uint256) {
        require(_b <= _a,"Math error");
        uint256 c = _a - _b;

        return c;
    }

     
    function add(uint256 _a, uint256 _b) internal pure returns (uint256) {
        uint256 c = _a + _b;
        require(c >= _a,"Math error");

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0,"Math error");
        return a % b;
    }
}


 
contract ERC20 is IERC20 {
    using SafeMath for uint256;

    mapping (address => uint256) internal balances_;

    mapping (address => mapping (address => uint256)) private allowed_;

    uint256 private totalSupply_;

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function balanceOf(address _owner) public view returns (uint256) {
        return balances_[_owner];
    }

   
    function allowance(
        address _owner,
        address _spender
    )
      public
      view
      returns (uint256)
    {
        return allowed_[_owner][_spender];
    }

     
    function transfer(address _to, uint256 _value) public returns (bool) {
        require(_value <= balances_[msg.sender],"Invalid value");
        require(_to != address(0),"Invalid address");

        balances_[msg.sender] = balances_[msg.sender].sub(_value);
        balances_[_to] = balances_[_to].add(_value);
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

     
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed_[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

     
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    )
      public
      returns (bool)
    {
        require(_value <= balances_[_from],"Value is more than balance");
        require(_value <= allowed_[_from][msg.sender],"Value is more than alloved");
        require(_to != address(0),"Invalid address");

        balances_[_from] = balances_[_from].sub(_value);
        balances_[_to] = balances_[_to].add(_value);
        allowed_[_from][msg.sender] = allowed_[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;
    }

   
    function increaseApproval(
        address _spender,
        uint256 _addedValue
    )
      public
      returns (bool)
    {
        allowed_[msg.sender][_spender] = (allowed_[msg.sender][_spender].add(_addedValue));
        emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
        return true;
    }

     
    function decreaseApproval(
        address _spender,
        uint256 _subtractedValue
    )
      public
      returns (bool)
    {
        uint256 oldValue = allowed_[msg.sender][_spender];
        if (_subtractedValue >= oldValue) {
            allowed_[msg.sender][_spender] = 0;
        } else {
            allowed_[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed_[msg.sender][_spender]);
        return true;
    }

     
    function _mint(address _account, uint256 _amount) internal {
        require(_account != 0,"Invalid address");
        totalSupply_ = totalSupply_.add(_amount);
        balances_[_account] = balances_[_account].add(_amount);
        emit Transfer(address(0), _account, _amount);
    }

     
    function _burn(address _account, uint256 _amount) internal {
        require(_account != 0,"Invalid address");
        require(_amount <= balances_[_account],"Amount is more than balance");

        totalSupply_ = totalSupply_.sub(_amount);
        balances_[_account] = balances_[_account].sub(_amount);
        emit Transfer(_account, address(0), _amount);
    }

}


 
library SafeERC20 {
    function safeTransfer(
        IERC20 _token,
        address _to,
        uint256 _value
    )
      internal
    {
        require(_token.transfer(_to, _value),"Transfer error");
    }

    function safeTransferFrom(
        IERC20 _token,
        address _from,
        address _to,
        uint256 _value
    )
      internal
    {
        require(_token.transferFrom(_from, _to, _value),"Tranfer error");
    }

    function safeApprove(
        IERC20 _token,
        address _spender,
        uint256 _value
    )
      internal
    {
        require(_token.approve(_spender, _value),"Approve error");
    }
}


 
contract Pausable {
    event Paused();
    event Unpaused();

    bool public paused = false;


     
    modifier whenNotPaused() {
        require(!paused,"Contract is paused, sorry");
        _;
    }

     
    modifier whenPaused() {
        require(paused, "Contract is running now");
        _;
    }

}


 
contract ERC20Pausable is ERC20, Pausable {

    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transfer(_to, _value);
    }

    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool) {
        return super.transferFrom(_from, _to, _value);
    }

    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool) {
        return super.approve(_spender, _value);
    }

    function increaseApproval(address _spender, uint _addedValue) public whenNotPaused returns (bool success) {
        return super.increaseApproval(_spender, _addedValue);
    }

    function decreaseApproval(address _spender, uint _subtractedValue) public whenNotPaused returns (bool success) {
        return super.decreaseApproval(_spender, _subtractedValue);
    }
}

 
contract ATHLETICOToken is ERC20Pausable {
    string public constant name = "ATHLETICO TOKEN";
    string public constant symbol = "ATH";
    uint32 public constant decimals = 18;
    uint256 public INITIAL_SUPPLY = 1000000000 * 1 ether;  
    address public CrowdsaleAddress;
    bool public ICOover;

    mapping (address => bool) public kyc;
    mapping (address => uint256) public sponsors;

    event LogSponsor(
        address indexed from,
        uint256 value
    );

    constructor(address _CrowdsaleAddress) public {
    
        CrowdsaleAddress = _CrowdsaleAddress;
        _mint(_CrowdsaleAddress, INITIAL_SUPPLY);
    }


    modifier onlyOwner() {
        require(msg.sender == CrowdsaleAddress,"Only CrowdSale contract can run this");
        _;
    }
    
    modifier validDestination( address to ) {
        require(to != address(0),"Empty address");
        require(to != address(this),"RESTO Token address");
        _;
    }
    
    modifier isICOover {
        if (msg.sender != CrowdsaleAddress){
            require(ICOover == true,"Transfer of tokens is prohibited until the end of the ICO");
        }
        _;
    }
    
     
    function transfer(address _to, uint256 _value) public validDestination(_to) isICOover returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) 
    public validDestination(_to) isICOover returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }

    
   
    function mint(address to, uint256 _value) public onlyOwner {
        _mint(to, _value);
    }


    
    function burn(uint256 _value) public {
        _burn(msg.sender, _value);
        sponsors[msg.sender] = sponsors[msg.sender].add(_value);
        emit LogSponsor(msg.sender, _value);
    }

     
    function kycPass(address _investor) public onlyOwner {
        kyc[_investor] = true;
    }

     
    function kycNotPass(address _investor) public onlyOwner {
        kyc[_investor] = false;
    }

     
    function setICOover() public onlyOwner {
        ICOover = true;
    }

     
    function transferTokensFromSpecialAddress(address _from, address _to, uint256 _value) public onlyOwner whenNotPaused returns (bool){
        require (balances_[_from] >= _value,"Decrease value");
        
        balances_[_from] = balances_[_from].sub(_value);
        balances_[_to] = balances_[_to].add(_value);
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }

     
    function pause() public onlyOwner whenNotPaused {
        paused = true;
        emit Paused();
    }

     
    function unpause() public onlyOwner whenPaused {
        paused = false;
        emit Unpaused();
    }
 
}



 
contract Ownable {
    address public owner;
    address public DAOContract;
    address private candidate;

    constructor() public {
        owner = msg.sender;
        DAOContract = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Access denied");
        _;
    }

    modifier onlyDAO() {
        require(msg.sender == DAOContract,"Access denied");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0),"Invalid address");
        candidate = _newOwner;
    }

    function setDAOContract(address _newDAOContract) public onlyOwner {
        require(_newDAOContract != address(0),"Invalid address");
        DAOContract = _newDAOContract;
    }


    function confirmOwnership() public {
        require(candidate == msg.sender,"Only from candidate");
        owner = candidate;
        delete candidate;
    }

}


contract TeamAddress {

}


contract BountyAddress {

}


 
contract Crowdsale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for ATHLETICOToken;

    event LogStateSwitch(State newState);
    event LogRefunding(address indexed to, uint256 amount);
    mapping(address => uint) public crowdsaleBalances;

    uint256 public softCap = 250 * 1 ether;
    address internal myAddress = this;
    ATHLETICOToken public token = new ATHLETICOToken(myAddress);
    uint64 public crowdSaleStartTime;       
    uint64 public crowdSaleEndTime = 1559347200;        
    uint256 internal minValue = 0.005 ether;

     
    TeamAddress public teamAddress = new TeamAddress();
    BountyAddress public bountyAddress = new BountyAddress();
      
     
    uint256 public rate;

     
    uint256 public weiRaised;

    event LogWithdraw(
        address indexed from, 
        address indexed to, 
        uint256 amount
    );

    event LogTokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

     
    enum State { 
        Init,    
        CrowdSale,
        Refunding,
        WorkTime
    }

    State public currentState = State.Init;

    modifier onlyInState(State state){ 
        require(state==currentState); 
        _; 
    }


    constructor() public {
        uint256 totalTokens = token.INITIAL_SUPPLY();
         
        _deliverTokens(teamAddress, totalTokens.div(10));
        _deliverTokens(bountyAddress, totalTokens.div(20));

        rate = 20000;
        setState(State.CrowdSale);
        crowdSaleStartTime = uint64(now);
    }

     
    function finishCrowdSale() public onlyInState(State.CrowdSale) {
        require(now >= crowdSaleEndTime || myAddress.balance >= softCap, "Too early");
        if(myAddress.balance >= softCap) {
        setState(State.WorkTime);
        token.setICOover();
        } else {
        setState(State.Refunding);
        }
    }


     
    function () external payable {
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);

        crowdsaleBalances[_beneficiary] = crowdsaleBalances[_beneficiary].add(weiAmount);
        
        emit LogTokensPurchased(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

    }


    function setState(State _state) internal {
        currentState = _state;
        emit LogStateSwitch(_state);
    }


     
    function pauseCrowdsale() public onlyOwner {
        token.pause();
    }

     
    function unpauseCrowdsale() public onlyOwner {
        token.unpause();
    }

     
    function setRate(uint256 _newRate) public onlyDAO {
        rate = _newRate;
    }

     
    function setKYCpassed(address _investor) public onlyDAO returns(bool){
        token.kycPass(_investor);
        return true;
    }

     
    function setKYCNotPassed(address _investor) public onlyDAO returns(bool){
        token.kycNotPass(_investor);
        return true;
    }

     
    function transferTokensFromTeamAddress(address _investor, uint256 _value) public onlyDAO returns(bool){
        token.transferTokensFromSpecialAddress(address(teamAddress), _investor, _value); 
        return true;
    } 

    
     
    function transferTokensFromBountyAddress(address _investor, uint256 _value) public onlyDAO returns(bool){
        token.transferTokensFromSpecialAddress(address(bountyAddress), _investor, _value); 
        return true;
    } 
    
     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view{
        require(_beneficiary != address(0),"Invalid address");
        require(_weiAmount >= minValue,"Min amount is 0.005 ether");
        require(currentState != State.Refunding, "Only for CrowdSale and Work stage.");
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.safeTransfer(_beneficiary, _tokenAmount);
    }


      
    function transferTokens(address _newInvestor, uint256 _tokenAmount) public onlyDAO {
        _deliverTokens(_newInvestor, _tokenAmount);
    }

      
    function mintTokensToWinners(address _address, uint256 _tokenAmount) public onlyDAO {
        require(currentState == State.WorkTime, "CrowdSale is not finished yet. Access denied.");
        token.mint(_address, _tokenAmount);
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
        
    }


     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 bonus = 0;
        uint256 resultAmount = _weiAmount;


         
        if (now >= crowdSaleStartTime && now < 1546300800) {
            bonus = 100;
        }
        if (now >= 1546300800 && now < 1548979200) {
            bonus = 50;
        }
        if (now >= 1548979200 && now < 1551398400) {
            bonus = 25;
        }
        
        if (bonus > 0) {
            resultAmount += _weiAmount.mul(bonus).div(100);
        }
        return resultAmount.mul(rate);
    }

     
    function refund() public payable{
        require(currentState == State.Refunding, "Only for Refunding stage.");
         
        uint value = crowdsaleBalances[msg.sender]; 
        crowdsaleBalances[msg.sender] = 0; 
        msg.sender.transfer(value);
        emit LogRefunding(msg.sender, value);
    }

     
    function withdrawFunds (address _to, uint256 _value) public onlyDAO {
        require(currentState == State.WorkTime, "CrowdSale is not finished yet. Access denied.");
        require (myAddress.balance >= _value,"Value is more than balance");
        require(_to != address(0),"Invalid address");
        _to.transfer(_value);
        emit LogWithdraw(msg.sender, _to, _value);
    }

}
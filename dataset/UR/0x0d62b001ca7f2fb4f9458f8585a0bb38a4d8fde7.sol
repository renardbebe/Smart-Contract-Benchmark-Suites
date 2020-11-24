 

 

pragma solidity ^0.4.24;


 
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

     
    function _burnFrom(address _account, uint256 _amount) internal {
        require(_amount <= allowed_[_account][msg.sender],"Amount is more than alloved");

         
         
        allowed_[_account][msg.sender] = allowed_[_account][msg.sender].sub(_amount);
        _burn(_account, _amount);
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

 
contract RESTOToken is ERC20Pausable {
    string public constant name = "RESTO";
    string public constant symbol = "RESTO";
    uint32 public constant decimals = 18;
    uint256 public INITIAL_SUPPLY = 1100000000 * 1 ether;  
    address public CrowdsaleAddress;
    uint64 crowdSaleEndTime = 1544745600;        

    mapping (address => bool) internal kyc;


    constructor(address _CrowdsaleAddress) public {
    
        CrowdsaleAddress = _CrowdsaleAddress;
        _mint(_CrowdsaleAddress, INITIAL_SUPPLY);
    }

    modifier kyc_passed(address _investor) {
        if (_investor != CrowdsaleAddress){
            require(kyc[_investor],"For transfer tokens you need to go through the procedure KYC");
        }
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == CrowdsaleAddress,"Only CrowdSale contract can run this");
        _;
    }
    
    modifier validDestination( address to ) {
        require(to != address(0x0),"Empty address");
        require(to != address(this),"RESTO Token address");
        _;
    }
    
    modifier isICOover {
        if (msg.sender != CrowdsaleAddress){
            require(now > crowdSaleEndTime,"Transfer of tokens is prohibited until the end of the ICO");
        }
        _;
    }
    
     
    function transfer(address _to, uint256 _value) public validDestination(_to) kyc_passed(msg.sender) isICOover returns (bool) {
        return super.transfer(_to, _value);
    }

     
    function transferFrom(address _from, address _to, uint256 _value) 
    public validDestination(_to) kyc_passed(msg.sender) isICOover returns (bool) 
    {
        return super.transferFrom(_from, _to, _value);
    }

    
     
    function kycPass(address _investor) public onlyOwner {
        kyc[_investor] = true;
    }


     
    function transferTokensFromSpecialAddress(address _from, address _to, uint256 _value) public onlyOwner whenNotPaused returns (bool){
        uint256 value = _value;
        require (value >= 1,"Min value is 1");
        value = value.mul(1 ether);
        require (balances_[_from] >= value,"Decrease value");
        
        balances_[_from] = balances_[_from].sub(value);
        balances_[_to] = balances_[_to].add(value);
        
        emit Transfer(_from, _to, value);
        
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

    function() external payable {
        revert("The token contract don`t receive ether");
    }  
}



 
contract Ownable {
    address public owner;
    address public manager;
    address candidate;

    constructor() public {
        owner = msg.sender;
        manager = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Access denied");
        _;
    }

    modifier restricted() {
        require(msg.sender == owner || msg.sender == manager,"Access denied");
        _;
    }

    function transferOwnership(address _newOwner) public onlyOwner {
        require(_newOwner != address(0),"Invalid address");
        candidate = _newOwner;
    }

    function setManager(address _newManager) public onlyOwner {
        require(_newManager != address(0),"Invalid address");
        manager = _newManager;
    }


    function confirmOwnership() public {
        require(candidate == msg.sender,"Only from candidate");
        owner = candidate;
        delete candidate;
    }

}


contract TeamAddress1 {
    function() external payable {
        revert("The contract don`t receive ether");
    } 
}


contract TeamAddress2 {
    function() external payable {
        revert("The contract don`t receive ether");
    } 
}


contract MarketingAddress {
    function() external payable {
        revert("The contract don`t receive ether");
    } 
}


contract RetailersAddress {
    function() external payable {
        revert("The contract don`t receive ether");
    } 
}


contract ReserveAddress {
    function() external payable {
        revert("The contract don`t receive ether");
    } 
}


contract BountyAddress {
    function() external payable {
        revert("The contract don`t receive ether");
    } 
}


 
contract Crowdsale is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for RESTOToken;

    uint256 hardCap = 50000 * 1 ether;
    address myAddress = this;
    RESTOToken public token = new RESTOToken(myAddress);
    uint64 crowdSaleStartTime = 1537401600;      
    uint64 crowdSaleEndTime = 1544745600;        

     
    TeamAddress1 public teamAddress1 = new TeamAddress1();
    TeamAddress2 public teamAddress2 = new TeamAddress2();
    MarketingAddress public marketingAddress = new MarketingAddress();
    RetailersAddress public retailersAddress = new RetailersAddress();
    ReserveAddress public reserveAddress = new ReserveAddress();
    BountyAddress public bountyAddress = new BountyAddress();
      
     
    uint256 public rate;

     
    uint256 public weiRaised;

    event Withdraw(
        address indexed from, 
        address indexed to, 
        uint256 amount
    );

    event TokensPurchased(
        address indexed purchaser,
        address indexed beneficiary,
        uint256 value,
        uint256 amount
    );

    constructor() public {
        uint256 totalTokens = token.INITIAL_SUPPLY();
         
        _deliverTokens(teamAddress1, totalTokens.mul(45).div(1000));
        _deliverTokens(teamAddress2, totalTokens.mul(135).div(1000));
        _deliverTokens(marketingAddress, totalTokens.mul(18).div(100));
        _deliverTokens(retailersAddress, totalTokens.mul(9).div(100));
        _deliverTokens(reserveAddress, totalTokens.mul(8).div(100));
        _deliverTokens(bountyAddress, totalTokens.div(100));

        rate = 10000;
    }

     
     
     

     
    function () external payable {
        require(msg.data.length == 0,"Only for simple payments");
        buyTokens(msg.sender);
    }

     
    function buyTokens(address _beneficiary) public payable {
        uint256 weiAmount = msg.value;
        _preValidatePurchase(_beneficiary, weiAmount);

         
        uint256 tokens = _getTokenAmount(weiAmount);

         
        weiRaised = weiRaised.add(weiAmount);

        _processPurchase(_beneficiary, tokens);
        
        emit TokensPurchased(
            msg.sender,
            _beneficiary,
            weiAmount,
            tokens
        );

    }

     
     
     

     
    function pauseCrowdsale() public onlyOwner {
        token.pause();
    }

     
    function unpauseCrowdsale() public onlyOwner {
        token.unpause();
    }

     
    function setKYCpassed(address _investor) public restricted returns(bool){
        token.kycPass(_investor);
        return true;
    }

     
    function transferTokensFromTeamAddress1(address _investor, uint256 _value) public restricted returns(bool){
        token.transferTokensFromSpecialAddress(address(teamAddress1), _investor, _value); 
        return true;
    } 

     
    function transferTokensFromTeamAddress2(address _investor, uint256 _value) public restricted returns(bool){
        require (now >= (crowdSaleEndTime + 365 days), "Only after 1 year");
        token.transferTokensFromSpecialAddress(address(teamAddress2), _investor, _value); 
        return true;
    } 
    
     
    function transferTokensFromMarketingAddress(address _investor, uint256 _value) public restricted returns(bool){
        token.transferTokensFromSpecialAddress(address(marketingAddress), _investor, _value); 
        return true;
    } 
    
     
    function transferTokensFromRetailersAddress(address _investor, uint256 _value) public restricted returns(bool){
        token.transferTokensFromSpecialAddress(address(retailersAddress), _investor, _value); 
        return true;
    } 

     
    function transferTokensFromReserveAddress(address _investor, uint256 _value) public restricted returns(bool){
        token.transferTokensFromSpecialAddress(address(reserveAddress), _investor, _value); 
        return true;
    } 

     
    function transferTokensFromBountyAddress(address _investor, uint256 _value) public restricted returns(bool){
        token.transferTokensFromSpecialAddress(address(bountyAddress), _investor, _value); 
        return true;
    } 
    
     
    function _preValidatePurchase(address _beneficiary, uint256 _weiAmount) internal view{
        require(_beneficiary != address(0),"Invalid address");
        require(_weiAmount != 0,"Invalid amount");
        require((now > crowdSaleStartTime && now <= crowdSaleEndTime) || now > 1604188800,"At this time contract don`t sell tokens, sorry");
        require(weiRaised < hardCap,"HardCap is passed, contract don`t accept ether.");
    }

     
    function _deliverTokens(address _beneficiary, uint256 _tokenAmount) internal {
        token.safeTransfer(_beneficiary, _tokenAmount);
    }


      
    function transferTokens(address _newInvestor, uint256 _tokenAmount) public restricted {
        uint256 value = _tokenAmount;
        require (value >= 1,"Min _tokenAmount is 1");
        value = value.mul(1 ether);        
        _deliverTokens(_newInvestor, value);
    }

     
    function _processPurchase(address _beneficiary, uint256 _tokenAmount) internal {
        _deliverTokens(_beneficiary, _tokenAmount);
    }


     
    function _getTokenAmount(uint256 _weiAmount) internal view returns (uint256) {
        uint256 bonus = 0;
        uint256 resultAmount = _weiAmount;
         
        if (now < 1539129600) {
             
            if (_weiAmount >= 100 * 1 ether) {
                bonus = 300;
            } else {
                bonus = 100;
            }
        } else {
             
            if (_weiAmount >= 100 * 1 ether) {
                bonus = 200;
            } else {
                 
                if (now >= 1539129600 && now < 1539734400) {
                    bonus = 40;
                }
                if (now >= 1539734400 && now < 1540339200) {
                    bonus = 30;
                }
                if (now >= 1540339200 && now < 1541030400) {
                    bonus = 20;
                }
                if (now >= 1541030400 && now < 1542326400) {
                    bonus = 10;
                }
            }
        }
        if (bonus > 0) {
            resultAmount += _weiAmount.mul(bonus).div(100);
        }
        return resultAmount.mul(rate);
    }

     
    function forwardFunds() public onlyOwner {
        uint256 transferValue = myAddress.balance.div(8);

         
        address wallet1 = 0x0C4324DC212f7B09151148c3960f71904E5C074D;
        address wallet2 = 0x49C0fAc36178DB055dD55df6a6656dd457dc307A;
        address wallet3 = 0x510aC42D296D0b06d5B262F606C27d5cf22B9726;
        address wallet4 = 0x48dfeA3ce1063191B45D06c6ECe7462B244A40B6;
        address wallet5 = 0x5B1689B453bb0DBd38A0d9710a093A228ab13170;
        address wallet6 = 0xDFA0Cba1D28E625C3f3257B4758782164e4622f2;
        address wallet7 = 0xF3Ff96FE7eE76ACA81aFb180264D6A31f726BAbE;
        address wallet8 = 0x5384EFFdf2bb24a8b0489633A64D4Bfc53BdFEb6;

        wallet1.transfer(transferValue);
        wallet2.transfer(transferValue);
        wallet3.transfer(transferValue);
        wallet4.transfer(transferValue);
        wallet5.transfer(transferValue);
        wallet6.transfer(transferValue);
        wallet7.transfer(transferValue);
        wallet8.transfer(myAddress.balance);
    }
    
    function withdrawFunds (address _to, uint256 _value) public onlyOwner {
        require (now > crowdSaleEndTime, "CrowdSale is not finished yet. Access denied.");
        require (myAddress.balance >= _value,"Value is more than balance");
        require(_to != address(0),"Invalid address");
        _to.transfer(_value);
        emit Withdraw(msg.sender, _to, _value);
    }

}
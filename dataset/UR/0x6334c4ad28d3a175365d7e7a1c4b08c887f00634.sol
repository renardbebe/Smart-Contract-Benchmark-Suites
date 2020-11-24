 

pragma solidity ^0.4.16;
 

 
library SafeMath {

    function mul(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function add(uint256 a, uint256 b) internal constant returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

}

contract token {

    mapping (address => uint256) public balanceOf;
    function transfer(address _to, uint256 _value);

    }

contract ICO {
    using SafeMath for uint256;
     
    enum State {
        Ongoin,
        Successful
    }
     
    State public state = State.Ongoin;  
    uint256 public startTime = now;  
     
    uint256 public price = 1500;  
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public ICOdeadline;  
    uint256 public closedAt;  
    token public tokenReward;  
    address public creator;  
    address public beneficiary;  
    string public campaignUrl;  
    uint8 constant version = 1;

     
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(
        address _creator,
        address _beneficiary,
        string _url,
        uint256 _ICOdeadline);
    event LogContributorsPayout(address _addr, uint _amount);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

     
    function ICO (string _campaignUrl, token _addressOfTokenUsedAsReward, uint256 _timeInDaysForICO) public {
        creator = msg.sender;  
        beneficiary = msg.sender;  
        campaignUrl = _campaignUrl;  
        tokenReward = token(_addressOfTokenUsedAsReward);  
        ICOdeadline = startTime + _timeInDaysForICO * 1 days;  

         
        LogFunderInitialized(
            creator,
            beneficiary,
            campaignUrl,
            ICOdeadline);
    }

     
    function contribute() public notFinished payable {

        uint256 tokenBought;
        totalRaised = totalRaised.add(msg.value);  
        tokenBought = msg.value.mul(price);  
        totalDistributed = totalDistributed.add(tokenBought);  
        require(beneficiary.send(msg.value));  
        tokenReward.transfer(msg.sender,tokenBought);  
        
         
        LogFundingReceived(msg.sender, msg.value, totalRaised);
        LogContributorsPayout(msg.sender, tokenBought);
        checkIfFundingCompleteOrExpired();

    }

     
    function checkIfFundingCompleteOrExpired() public {
        
        if(now > ICOdeadline && state!=State.Successful ) {  
            state = State.Successful;  
            closedAt = now;  
            
            LogFundingSuccessful(totalRaised);  
            finished();  
        }
    }

    
    function finished() public {  
        require(state == State.Successful);  
        require(beneficiary.send(this.balance));  

        uint256 remaining = tokenReward.balanceOf(this);  
        tokenReward.transfer(beneficiary,remaining);  

        LogBeneficiaryPaid(beneficiary);
    }

     
    function () public payable {
        contribute();  
    }
}
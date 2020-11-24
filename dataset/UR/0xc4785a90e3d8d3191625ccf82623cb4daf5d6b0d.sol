 

pragma solidity ^0.4.20;
 

 
library SafeMath {

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }


    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
}

 
contract FiatContract {
 
  function EUR(uint _id) constant public returns (uint256);

}

 
contract DateTimeAPI {
        
    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour) constant public returns (uint timestamp);

}

 
contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);

}

 
contract NETRico {

    FiatContract price = FiatContract(0x8055d0504666e2B6942BeB8D6014c964658Ca591);  

    DateTimeAPI dateTimeContract = DateTimeAPI(0x1a6184CD4C5Bea62B0116de7962EE7315B7bcBce); 

    using SafeMath for uint256;
     
    enum State {
        Stage1,
        Stage2,
        Stage3,
        Stage4,
        Successful
    }
     
    State public state = State.Stage1;  
    uint256 public startTime = dateTimeContract.toTimestamp(2018,4,1,0);  
    uint256 public deadline = dateTimeContract.toTimestamp(2019,3,27,0);  
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public completedAt;  
    token public tokenReward;  
    address public creator;  
    string public campaignUrl;  
    string public version = '2';

     
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(
        address _creator,
        string _url);
    event LogContributorsPayout(address _addr, uint _amount);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }
     
    function NETRico (string _campaignUrl, token _addressOfTokenUsedAsReward) public {
        creator = 0xB987B463c7573f0B7b6eD7cc8E5Fab9042272065;
         
        campaignUrl = _campaignUrl;
        tokenReward = token(_addressOfTokenUsedAsReward);

        emit LogFunderInitialized(
            creator,
            campaignUrl
            );
    }

     
    function contribute() public notFinished payable {
        require(now >= startTime);

        uint256 tokenBought;  
        uint256 tokenPrice = price.EUR(0);  

        totalRaised = totalRaised.add(msg.value);  

        tokenPrice = tokenPrice.mul(2);  
        tokenPrice = tokenPrice.div(10 ** 8);  

        tokenBought = msg.value.div(tokenPrice);  
        tokenBought = tokenBought.mul(10 ** 10);  

        require(tokenBought >= 100 * 10 ** 18);  
        
         
        if (state == State.Stage1){
            tokenBought = tokenBought.mul(2);  
        } else if (state == State.Stage2){
            tokenBought = tokenBought.mul(175);
            tokenBought = tokenBought.div(100);  
        } else if (state == State.Stage3){
            tokenBought = tokenBought.mul(15);
            tokenBought = tokenBought.div(10);  
        } else if (state == State.Stage4){
            tokenBought = tokenBought.mul(125);
            tokenBought = tokenBought.div(100);  
        }

        totalDistributed = totalDistributed.add(tokenBought);  
        
        tokenReward.transfer(msg.sender,tokenBought);  
        
        creator.transfer(msg.value);  
        emit LogBeneficiaryPaid(creator);
        
         
        emit LogFundingReceived(msg.sender, msg.value, totalRaised);
        emit  LogContributorsPayout(msg.sender,tokenBought);

        checkIfFundingCompleteOrExpired();
    }

     
    function checkIfFundingCompleteOrExpired() public {

        if(now > deadline && state != State.Successful){

            state = State.Successful;  
            completedAt = now;  

            emit LogFundingSuccessful(totalRaised);  

            finished();
        } else if(state == State.Stage3 && now > dateTimeContract.toTimestamp(2018,12,27,0)){

            state = State.Stage4;
            
        } else if(state == State.Stage2 && now > dateTimeContract.toTimestamp(2018,9,28,0)){

            state = State.Stage3;
            
        } else if(state == State.Stage1 && now > dateTimeContract.toTimestamp(2018,6,30,0)){

            state = State.Stage2;

        }
    }

     
    function finished() public {  
        require(state == State.Successful);  
        
        uint256 remainder = tokenReward.balanceOf(this);  
         
        if(address(this).balance > 0) {
            creator.transfer(address(this).balance);
            emit LogBeneficiaryPaid(creator);
        }
 
        tokenReward.transfer(creator,remainder);  
        emit LogContributorsPayout(creator, remainder);

    }

     
    function claimTokens(token _address) public{
        require(state == State.Successful);  
        require(msg.sender == creator);

        uint256 remainder = _address.balanceOf(this);  
        _address.transfer(creator,remainder);  
        
    }

     
    function() public payable {
        contribute();
    }
    
}
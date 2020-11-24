 

pragma solidity 0.5.5;
 

 
 
 
library SafeMath {
    function add(uint a, uint b) internal pure returns(uint c) {
        c = a + b;
        require(c >= a);
    }

    function sub(uint a, uint b) internal pure returns(uint c) {
        require(b <= a);
        c = a - b;
    }

    function mul(uint a, uint b) internal pure returns(uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }

    function div(uint a, uint b) internal pure returns(uint c) {
        require(b > 0);
        c = a / b;
    }
}

 
 
 
interface ERC20Interface {
    function totalSupply() external returns(uint);

    function balanceOf(address tokenOwner) external returns(uint balance);

    function allowance(address tokenOwner, address spender) external returns(uint remaining);

    function transfer(address to, uint tokens) external returns(bool success);

    function approve(address spender, uint tokens) external returns(bool success);

    function transferFrom(address from, address to, uint tokens) external returns(bool success);

    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

 
 
 
interface DateTimeAPI {

    function toTimestamp(uint16 year, uint8 month, uint8 day, uint8 hour, uint8 minute) external returns(uint timestamp);

}

 
 
 
contract ICO {

 
 
 
    DateTimeAPI dateTimeContract = DateTimeAPI(0x1a6184CD4C5Bea62B0116de7962EE7315B7bcBce); 
     
     
     

    using SafeMath
    for uint256;

    enum State {
         
        preSale,
        ICO,
        finishing,
        extended,
        successful
    }

     

     
    State public state = State.preSale;  
    

     
    uint256 public startTime = dateTimeContract.toTimestamp(2019, 3, 20, 0, 0);
    uint256 public ICOdeadline = dateTimeContract.toTimestamp(2019, 6, 5, 23, 59);
    uint256 public completedAt;

     
    ERC20Interface public tokenReward;
    uint256 public presaleLimit = 200000000 * 10 ** 18;  
    uint256 public ICOLimit = 360000000 * 10 ** 18;  

     
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public totalReferral;  
    mapping(address => uint256) public referralBalance;  
    uint256[7] public rates = [1000, 800, 750, 700, 650, 600, 500];
    
     
    address public creator;
    address payable public beneficiary;
    string public version = '0.3';

     
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(
        address _creator,
        uint256 _ICOdeadline);
    event LogContributorsPayout(address _addr, uint _amount);
    event LogStateCheck(State current);

    modifier notFinished() {
        require(state != State.successful);
        _;
    }

     
    constructor(ERC20Interface _addressOfTokenUsedAsReward, address payable _beneficiary) public {

        creator = msg.sender;
        tokenReward = _addressOfTokenUsedAsReward;
        beneficiary = _beneficiary;

        emit LogFunderInitialized(
            creator,
            ICOdeadline);

    }

     
    function contribute(address referralAddress) public notFinished payable {

         
        require(now >= startTime,"Too early for the sale begin");

        uint256 tokenBought = 0;

        totalRaised = totalRaised.add(msg.value);  

         
        if (state == State.preSale) {

            if (now <= dateTimeContract.toTimestamp(2019, 3, 22, 23, 59)) {  

                tokenBought = msg.value.mul(rates[0]);

            } else if (now <= dateTimeContract.toTimestamp(2019, 3, 28, 23, 59)) {  

                tokenBought = msg.value.mul(rates[1]);

            } else {  

                tokenBought = msg.value.mul(rates[2]);

            }

        } else if (state == State.ICO) {

             
            require(now > dateTimeContract.toTimestamp(2019, 4, 20, 0, 0),"Too early for the ICO begin"); 

            if (now <= dateTimeContract.toTimestamp(2019, 4, 22, 23, 59)) {  

                tokenBought = msg.value.mul(rates[3]);

            } else if (now <= dateTimeContract.toTimestamp(2019, 4, 28, 23, 59)) {  

                tokenBought = msg.value.mul(rates[4]);

            } else if (now <= dateTimeContract.toTimestamp(2019, 5, 4, 23, 59)) {  

                tokenBought = msg.value.mul(rates[5]);

            } else {  

                tokenBought = msg.value.mul(rates[6]);

            }

        } else if (state == State.finishing) {  

            revert("Purchases disabled while extension Poll");

        } else {  

            tokenBought = msg.value.mul(rates[6]);

        }

         
        if (msg.value >= 100 ether) {
            tokenBought = tokenBought.mul(11);
            tokenBought = tokenBought.div(10);
        }

         
         
        if (referralAddress != address(0) && referralAddress != msg.sender) {
            uint256 bounty = tokenBought.mul(3);
            bounty = bounty.div(100);
            totalReferral = totalReferral.add(bounty);
            referralBalance[referralAddress] = referralBalance[referralAddress].add(bounty);
        }

        if (state == State.preSale) {

            require(totalDistributed.add(tokenBought.add(totalReferral)) <= presaleLimit, "Presale Limit exceded");

        } else {

            require(totalDistributed.add(tokenBought.add(totalReferral)) <= ICOLimit, "ICO Limit exceded");

        }

         
        if (totalRaised >= 4000 ether) {

            beneficiary.transfer(address(this).balance);

            emit LogBeneficiaryPaid(beneficiary);
        }

        totalDistributed = totalDistributed.add(tokenBought);  

        require(tokenReward.transfer(msg.sender, tokenBought), "Transfer could not be made");

        emit LogFundingReceived(msg.sender, msg.value, totalRaised);
        emit LogContributorsPayout(msg.sender, tokenBought);

        checkIfFundingCompleteOrExpired();
    }

     
    function checkIfFundingCompleteOrExpired() public {

         
        if (state == State.preSale && now > dateTimeContract.toTimestamp(2019, 4, 11, 23, 59)) {

             
            state = State.ICO;

        } else if (state == State.ICO && now > ICOdeadline) {  

             
            state = State.finishing;

        } else if (state == State.extended && now > ICOdeadline) {  

            state = State.successful;  
            completedAt = now;  

            emit LogFundingSuccessful(totalRaised);  
            finished();  

        }

        emit LogStateCheck(state);

    }

     
    function finished() public {  

         
        require(state == State.successful, "Wrong Stage");

        beneficiary.transfer(address(this).balance);

        emit LogBeneficiaryPaid(beneficiary);

    }

     
    function claimReferral() public {

         
        require(state == State.successful, "Wrong Stage");

        uint256 bounty = referralBalance[msg.sender];  
        referralBalance[msg.sender] = 0;  

         
        require(tokenReward.transfer(msg.sender, bounty), "Transfer could not be made");

         
        emit LogContributorsPayout(msg.sender, bounty);
    }

     
    function retrieveTokens() public {

         
        require(msg.sender == creator,"You are not the creator");
         
        require(state == State.successful, "Wrong Stage");
         
        require(now >= completedAt.add(30 days), "Too early to retrieve");

        uint256 remanent = tokenReward.balanceOf(address(this));

        require(tokenReward.transfer(beneficiary, remanent), "Transfer could not be made");
    }

     
    function extension(bool pollResult) public {

         
        require(msg.sender == creator,"You are not the creator");
         
        require(state == State.finishing, "Wrong Stage");

         
        if (pollResult == true) {  
             
            state = State.extended;
             
            ICOdeadline = now.add(30 days);
        } else {  
             
            state = State.successful;
             
            completedAt = now;

            emit LogFundingSuccessful(totalRaised);  
            finished();  

        }
    }

     
    function() external payable {

        contribute(address(0));  

    }
}
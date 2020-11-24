 

pragma solidity ^0.4.18;
 

 
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
}

contract token {

    function balanceOf(address _owner) public constant returns (uint256 balance);
    function transfer(address _to, uint256 _value) public returns (bool success);

    }

 
contract admined {
    address public admin;  
    
     
    function admined() internal {
        admin = msg.sender;  
        Admined(admin);
    }

     
    modifier onlyAdmin() {  
        require(msg.sender == admin);
        _;
    }

     
    function transferAdminship(address _newAdmin) onlyAdmin public {  
        admin = _newAdmin;
        TransferAdminship(admin);
    }

     
    event TransferAdminship(address newAdminister);
    event Admined(address administer);

}


contract ICO is admined {
    using SafeMath for uint256;
     
    enum State {
        EarlyBird,
        PreSale,
        TokenSale,
        ITO,
        Successful
    }
     
    uint256 public priceOfEthOnEUR;
    State public state = State.EarlyBird;  
    uint256 public startTime = now;  
    uint256 public price;  
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public stageDistributed;  
    uint256 public completedAt;  
    token public tokenReward;  
    address public creator;  
    string public campaignUrl;  
    string public version = '1';

     
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);
    event LogFunderInitialized(
        address _creator,
        string _url,
        uint256 _initialRate);
    event LogContributorsPayout(address _addr, uint _amount);
    event PriceUpdate(uint256 _newPrice);
    event StageDistributed(State _stage, uint256 _stageDistributed);

    modifier notFinished() {
        require(state != State.Successful);
        _;
    }
     
    function ICO (string _campaignUrl, token _addressOfTokenUsedAsReward, uint256 _initialEURPriceOfEth) public {
        creator = msg.sender;
        campaignUrl = _campaignUrl;
        tokenReward = token(_addressOfTokenUsedAsReward);
        priceOfEthOnEUR = _initialEURPriceOfEth;
        price = SafeMath.div(priceOfEthOnEUR.mul(6666666666666666667),1000000000000000000);
        
        LogFunderInitialized(
            creator,
            campaignUrl,
            price
            );
        PriceUpdate(price);
    }

    function updatePriceOfEth(uint256 _newPrice) onlyAdmin public {
        priceOfEthOnEUR = _newPrice;
        price = SafeMath.div(priceOfEthOnEUR.mul(6666666666666666667),1000000000000000000);
        PriceUpdate(price);
    }

     
    function contribute() public notFinished payable {

        uint256 tokenBought;
        totalRaised = totalRaised.add(msg.value);

        if (state == State.EarlyBird){

            tokenBought = msg.value.mul(price);
            tokenBought = tokenBought.mul(4);  
            require(stageDistributed.add(tokenBought) <= 200000000 * (10 ** 18));

        } else if (state == State.PreSale){

            tokenBought = msg.value.mul(price);
            tokenBought = tokenBought.mul(15);  
            tokenBought = tokenBought.div(10);
            require(stageDistributed.add(tokenBought) <= 500000000 * (10 ** 18));

        } else if (state == State.TokenSale){

            tokenBought = msg.value.mul(price);  
            require(stageDistributed.add(tokenBought) <= 500000000 * (10 ** 18));

        } else if (state == State.ITO){

            tokenBought = msg.value.mul(price);  
            require(stageDistributed.add(tokenBought) <= 800000000 * (10 ** 18));

        } 

        totalDistributed = totalDistributed.add(tokenBought);
        stageDistributed = stageDistributed.add(tokenBought);
        tokenReward.transfer(msg.sender, tokenBought);
        
        LogFundingReceived(msg.sender, msg.value, totalRaised);
        LogContributorsPayout(msg.sender, tokenBought);
        
        checkIfFundingCompleteOrExpired();
    }

     
    function checkIfFundingCompleteOrExpired() public {
        
        if(state!=State.Successful){  
            
            if(state == State.EarlyBird && now > startTime.add(38 days)){  
                
                StageDistributed(state,stageDistributed);

                state = State.PreSale;
                stageDistributed = 0;
            
            } else if(state == State.PreSale && now > startTime.add(127 days)){  
                
                StageDistributed(state,stageDistributed);

                state = State.TokenSale;
                stageDistributed = 0;

            } else if(state == State.TokenSale && now > startTime.add(219 days)){  
            
                StageDistributed(state,stageDistributed);

                state = State.ITO;
                stageDistributed = 0;

            } else if(state == State.ITO && now > startTime.add(372 days)){  
                
                StageDistributed(state,stageDistributed);

                state = State.Successful;  
                completedAt = now;  
                LogFundingSuccessful(totalRaised);  
                finished();  
            
            }
        }
    }

     
    function payOut() public {
        require(msg.sender == creator);  
        require(creator.send(this.balance));
        LogBeneficiaryPaid(creator);
    }

     
    function finished() public {  
        require(state == State.Successful);
        uint256 remanent = tokenReward.balanceOf(this);

        require(creator.send(this.balance));
        tokenReward.transfer(creator,remanent);

        LogBeneficiaryPaid(creator);
        LogContributorsPayout(creator, remanent);
    }

    function () public payable {
        contribute();
    }
}
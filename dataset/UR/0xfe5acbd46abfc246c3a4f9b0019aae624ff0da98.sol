 

pragma solidity 0.4.25;
 

 
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


 
contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public;
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract admined {
     
    mapping(address => uint8) public level;
     
     
     

     
    constructor() internal {
        level[msg.sender] = 2;  
        emit AdminshipUpdated(msg.sender,2);  
    }

     
    modifier onlyAdmin(uint8 _level) {  
        require(level[msg.sender] >= _level );  
        _;
    }

     
    function adminshipLevel(address _newAdmin, uint8 _level) onlyAdmin(2) public {  
        require(_newAdmin != address(0));  
        level[_newAdmin] = _level;  
        emit AdminshipUpdated(_newAdmin,_level);  
    }

     
    event AdminshipUpdated(address _newAdmin, uint8 _level);

}

contract VSTERICO is admined {

    using SafeMath for uint256;
     
    enum State {
        PRESALE,
        MAINSALE,
        Successful
    }
     

     
    State public state = State.PRESALE;  
    uint256 constant public PRESALEStart = 1548979200;  
    uint256 constant public MAINSALEStart = 1554163200;  
    uint256 constant public SaleDeadline = 1564531200;  
    uint256 public completedAt;  
     
    uint256 public totalRaised;  
    uint256 public totalRefDistributed;  
    uint256 public totalEthRefDistributed;  
    uint256 public totalDistributed;  
    ERC20Basic public tokenReward = ERC20Basic(0xA2e13c4f0431B6f2B06BBE61a24B61CCBe13136A);  
    mapping(address => bool) referral;  

     
    address public creator;  
    address public fundsWallet = 0x62e0b52F0a7AD4bB7b87Ce41e132bCBC7173EB96;
    string public version = '0.2';  

     
    uint256 public USDPriceInWei;  
    string public USDPrice;

     
    event LogFundrisingInitialized(address indexed _creator);
    event LogFundingReceived(address indexed _addr, uint _amount, uint _currentTotal, address _referral);
    event LogBeneficiaryPaid(address indexed _beneficiaryAddress);
    event LogContributorsPayout(address indexed _addr, uint _amount);
    event LogFundingSuccessful(uint _totalRaised);

     
    modifier notFinished() {
        require(state != State.Successful);
        _;
    }

     
    constructor(uint _initialUSDInWei) public {

        creator = msg.sender;  
        USDPriceInWei = _initialUSDInWei;

        emit LogFundrisingInitialized(creator);  

    }

    function setReferralType(address _user, bool _type) onlyAdmin(1) public {
      referral[_user] = _type;
    }

     
    function contribute(address _target, uint256 _value, address _reff) public notFinished payable {
        require(now > PRESALEStart);  

        address user;
        uint remaining;
        uint256 tokenBought;
        uint256 temp;
        uint256 refBase;

         
        if(_target != address(0) && level[msg.sender] >= 1){
          user = _target;  
          remaining = _value.mul(1e18);  
          refBase = _value;  
        } else {  
          user = msg.sender;  
          remaining = msg.value.mul(1e18);  
          refBase = msg.value;  
        }

        totalRaised = totalRaised.add(remaining.div(1e18));  

         
        while(remaining > 0){

          (temp,remaining) = tokenBuyCalc(remaining);
          tokenBought = tokenBought.add(temp);

        }

        temp = 0;  

        totalDistributed = totalDistributed.add(tokenBought);  

         
        if(state == State.PRESALE){
          require(totalDistributed <= 5000000 * (10**18));
        }

         
        tokenReward.transfer(user,tokenBought);

         
        if(_reff != address(0) && _reff != user){  

           
          if(referral[_reff] == true){  
             
            if(state == State.PRESALE){ 
               
              _reff.transfer(refBase.div(10));
              totalEthRefDistributed = totalEthRefDistributed.add(refBase.div(10));

            } else { 
               
              _reff.transfer(refBase.div(20));
              totalEthRefDistributed = totalEthRefDistributed.add(refBase.div(20));

            }
          } else { 
             
            if(state == State.PRESALE){ 
               
              tokenReward.transfer(_reff,tokenBought.div(10));
              totalRefDistributed = totalRefDistributed.add(tokenBought.div(10));
            } else { 
               
              tokenReward.transfer(_reff,tokenBought.div(20));
              totalRefDistributed = totalRefDistributed.add(tokenBought.div(20));
            }
          }
        }

        emit LogFundingReceived(user, msg.value, totalRaised, _reff);  

        fundsWallet.transfer(address(this).balance);  
        emit LogBeneficiaryPaid(fundsWallet);  

        checkIfFundingCompleteOrExpired();  
    }


     
    function tokenBuyCalc(uint _value) internal view returns (uint sold,uint remaining) {

      uint256 tempPrice = USDPriceInWei;  

       
      if(state == State.PRESALE){  

            tempPrice = tempPrice.mul(400);  
            sold = _value.div(tempPrice);  

            return (sold,0);

      } else {  

            tempPrice = tempPrice.mul(600);  
            sold = _value.div(tempPrice);  

            return (sold,0);

        }
}

     
    function checkIfFundingCompleteOrExpired() public {

        if ( now > SaleDeadline && state != State.Successful){  

            state = State.Successful;  
            completedAt = now;  

            emit LogFundingSuccessful(totalRaised);  
            successful();  

        } else if(state == State.PRESALE && now >= MAINSALEStart ) {

            state = State.MAINSALE;  

        }

    }

     
    function successful() public {
        require(state == State.Successful);  

        uint256 temp = tokenReward.balanceOf(address(this));  

        tokenReward.transfer(creator,temp);  
        emit LogContributorsPayout(creator,temp);  

        fundsWallet.transfer(address(this).balance);  
        emit LogBeneficiaryPaid(fundsWallet);  
    }

     
    function setPrice(uint _value, string _price) public onlyAdmin(2) {

      USDPriceInWei = _value;
      USDPrice = _price;

    }

     
    function externalTokensRecovery(ERC20Basic _address) onlyAdmin(2) public{
        require(state == State.Successful);  

        uint256 remainder = _address.balanceOf(address(this));  
        _address.transfer(msg.sender,remainder);  

    }

     
    function () public payable {

         
         
        contribute(address(0),0,address(0));

    }
}
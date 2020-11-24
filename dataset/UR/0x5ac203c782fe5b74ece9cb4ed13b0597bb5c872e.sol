 

pragma solidity 0.5.8;

 


 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns(uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");
        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;
        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns(uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns(uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
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

 
contract admined {
     
    mapping(address => uint8) public level;
     
     
     

    constructor() internal {
        level[0x7a3a57c620fA468b304b5d1826CDcDe28E2b2b98] = 2;  
        emit AdminshipUpdated(0x7a3a57c620fA468b304b5d1826CDcDe28E2b2b98, 2);  
    }

     
    modifier onlyAdmin(uint8 _level) {  
         
        require(level[msg.sender] >= _level, "You dont have rights for this transaction");
        _;
    }

     
    function adminshipLevel(address _newAdmin, uint8 _level) public onlyAdmin(2) { 
        require(_newAdmin != address(0), "Address cannot be zero");  
        level[_newAdmin] = _level;  
        emit AdminshipUpdated(_newAdmin, _level);  
    }

     
    event AdminshipUpdated(address _newAdmin, uint8 _level);

}

 
 
 
contract ICO is admined {

    using SafeMath for uint256;

    enum State {
         
        OnSale,
        Successful
    }

     

     
    State public state = State.OnSale;  

     
    uint256 public SaleStartTime = now;
    uint256 public completedAt;

     
    ERC20Interface public tokenReward;

     
    uint256 public totalRaised;  
    uint256 public totalDistributed;  
    uint256 public totalBonusDistributed;  
    uint256 public constant rate = 2941;  
    uint256 public constant trancheSize = 52500000 * 1e18;
    uint256 public constant hardCap = 420000000 * 1e18;
    uint256 public constant softCap = 3000000 * 1e18;
    mapping(address => uint256) public invested;
    mapping(address => uint256) public received;
    mapping(address => uint256) public bonusReceived;

     
    address public owner;
    address payable public beneficiary;
    string public version = '1';

     
    event LogFundingInitialized(address _owner);
    event LogFundingReceived(address _addr, uint _amount, uint _currentTotal);
    event LogContributorsPayout(address _addr, uint _amount);
    event LogBeneficiaryPaid(address _beneficiaryAddress);
    event LogFundingSuccessful(uint _totalRaised);

    modifier notFinished() {
        require(state != State.Successful, "Sale have finished");
        _;
    }

     
    constructor(ERC20Interface _addressOfTokenUsedAsReward) public {

        tokenReward = _addressOfTokenUsedAsReward;
        owner = 0x7a3a57c620fA468b304b5d1826CDcDe28E2b2b98;
        beneficiary = 0x8605409D35f707714A83410BE9C8025dcefa9faC;

        emit LogFundingInitialized(owner);

    }

     
    function contribute(address _target, uint256 _value) public notFinished payable {

        address user;
        uint valueHandler;

        uint tokenBought;
        uint tokenBonus;

        uint bonusStack;
        uint trancheLeft;
        uint remaining;

        if (_target != address(0) && level[msg.sender] >= 1) {
            user = _target;
            valueHandler = _value;
        } else {
            user = msg.sender;
            valueHandler = msg.value;
             
            invested[msg.sender] = invested[msg.sender].add(msg.value);
        }

        require(valueHandler >= 0.1 ether, "Not enough value for this transaction");

        totalRaised = totalRaised.add(valueHandler);  

         
        tokenBought = valueHandler.mul(rate);
         
        remaining = valueHandler.mul(rate);

         
        if (remaining > 0 &&
            totalDistributed < trancheSize
        ) {
            trancheLeft = trancheSize.sub(totalDistributed);

            if (remaining < trancheLeft) {
                bonusStack = remaining.mul(4);
                tokenBonus = bonusStack.div(10);

                totalDistributed = totalDistributed.add(remaining);

                remaining = 0;
                bonusStack = 0;
                trancheLeft = 0;
            } else {
                bonusStack = trancheLeft.mul(4);
                tokenBonus = bonusStack.div(10);

                totalDistributed = totalDistributed.add(trancheLeft);

                remaining = remaining.sub(trancheLeft);
                bonusStack = 0;
                trancheLeft = 0;
            }
        }

         
        if (remaining > 0 &&
            totalDistributed >= trancheSize &&
            totalDistributed < trancheSize.mul(2)
        ) {
            trancheLeft = trancheSize.mul(2).sub(totalDistributed);

            if (remaining < trancheLeft) {
                bonusStack = remaining.mul(35);
                tokenBonus = tokenBonus.add(bonusStack.div(100));

                totalDistributed = totalDistributed.add(remaining);

                remaining = 0;
                bonusStack = 0;
                trancheLeft = 0;
            } else {
                bonusStack = trancheLeft.mul(35);
                tokenBonus = tokenBonus.add(bonusStack.div(100));

                totalDistributed = totalDistributed.add(trancheLeft);

                remaining = remaining.sub(trancheLeft);
                bonusStack = 0;
                trancheLeft = 0;
            }
        }

         
        if (remaining > 0 &&
            totalDistributed >= trancheSize.mul(2) &&
            totalDistributed < trancheSize.mul(3)
        ) {
            trancheLeft = trancheSize.mul(3).sub(totalDistributed);

            if (remaining < trancheLeft) {
                bonusStack = remaining.mul(3);
                tokenBonus = tokenBonus.add(bonusStack.div(10));

                totalDistributed = totalDistributed.add(remaining);

                remaining = 0;
                bonusStack = 0;
                trancheLeft = 0;
            } else {
                bonusStack = trancheLeft.mul(3);
                tokenBonus = tokenBonus.add(bonusStack.div(10));

                totalDistributed = totalDistributed.add(trancheLeft);

                remaining = remaining.sub(trancheLeft);
                bonusStack = 0;
                trancheLeft = 0;
            }
        }

         
        if (remaining > 0 &&
            totalDistributed >= trancheSize.mul(3) &&
            totalDistributed < trancheSize.mul(4)
        ) {
            trancheLeft = trancheSize.mul(4).sub(totalDistributed);

            if (remaining < trancheLeft) {
                bonusStack = remaining.mul(2);
                tokenBonus = tokenBonus.add(bonusStack.div(10));

                totalDistributed = totalDistributed.add(remaining);

                remaining = 0;
                bonusStack = 0;
                trancheLeft = 0;
            } else {
                bonusStack = trancheLeft.mul(2);
                tokenBonus = tokenBonus.add(bonusStack.div(10));

                totalDistributed = totalDistributed.add(trancheLeft);

                remaining = remaining.sub(trancheLeft);
                bonusStack = 0;
                trancheLeft = 0;
            }
        }

         
        if (remaining > 0 &&
            totalDistributed >= trancheSize.mul(4) &&
            totalDistributed < trancheSize.mul(5)
        ) {
            trancheLeft = trancheSize.mul(5).sub(totalDistributed);

            if (remaining < trancheLeft) {
                tokenBonus = tokenBonus.add(remaining.div(10));

                totalDistributed = totalDistributed.add(remaining);

                remaining = 0;
                bonusStack = 0;
                trancheLeft = 0;
            } else {
                tokenBonus = tokenBonus.add(trancheLeft.div(10));

                totalDistributed = totalDistributed.add(trancheLeft);

                remaining = remaining.sub(trancheLeft);
                bonusStack = 0;
                trancheLeft = 0;
            }
        }

         
        if (remaining > 0 &&
            totalDistributed >= trancheSize.mul(5) &&
            totalDistributed < trancheSize.mul(6)
        ) {
            trancheLeft = trancheSize.mul(6).sub(totalDistributed);

            if (remaining < trancheLeft) {
                bonusStack = remaining.mul(5);
                tokenBonus = tokenBonus.add(bonusStack.div(100));

                totalDistributed = totalDistributed.add(remaining);

                remaining = 0;
                bonusStack = 0;
                trancheLeft = 0;
            } else {
                bonusStack = trancheLeft.mul(5);
                tokenBonus = tokenBonus.add(bonusStack.div(100));

                totalDistributed = totalDistributed.add(trancheLeft);

                remaining = remaining.sub(trancheLeft);
                bonusStack = 0;
                trancheLeft = 0;
            }
        }

        totalDistributed = totalDistributed.add(remaining);
        totalBonusDistributed = totalBonusDistributed.add(tokenBonus);

        tokenReward.transfer(user, tokenBought.add(tokenBonus));
        received[user] = received[user].add(tokenBought);
        bonusReceived[user] = bonusReceived[user].add(tokenBonus);

        emit LogFundingReceived(user, valueHandler, totalRaised);  

        checkIfFundingCompleteOrExpired();  
    }

     
    function checkIfFundingCompleteOrExpired() public {

        if (totalDistributed.add(totalBonusDistributed) > hardCap.sub(rate)) {  

            state = State.Successful;  

            completedAt = now;  

            emit LogFundingSuccessful(totalRaised);  
            finished();  

        }
    }

    function withdrawEth() public onlyAdmin(2) {
        require(totalDistributed >= softCap, "Too early to retrieve funds");
        beneficiary.transfer(address(this).balance);
    }

    function getRefund() public notFinished {
        require(totalDistributed >= softCap, "Too early to retrieve funds");
        require(invested[msg.sender] > 0, "No eth to refund");
        require(
            tokenReward.transferFrom(
                msg.sender,
                address(this),
                received[msg.sender].add(bonusReceived[msg.sender])
            ),
            "Cannot retrieve tokens"
        );

        totalDistributed = totalDistributed.sub(received[msg.sender]);
        totalBonusDistributed = totalBonusDistributed.sub(bonusReceived[msg.sender]);
        received[msg.sender] = 0;
        bonusReceived[msg.sender] = 0;
        uint toTransfer = invested[msg.sender];
        invested[msg.sender] = 0;
        msg.sender.transfer(toTransfer);
    }

     
    function finished() public {  
         
        require(state == State.Successful, "Wrong Stage");

        uint256 remanent = tokenReward.balanceOf(address(this));

        require(tokenReward.transfer(beneficiary, remanent), "Transfer could not be made");

        beneficiary.transfer(address(this).balance);
        emit LogBeneficiaryPaid(beneficiary);
    }

     
    function () external payable {
        contribute(address(0), 0);
    }
}
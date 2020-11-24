 

pragma solidity ^0.4.24;


 
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }
        uint256 c = a * b;
        assert(c / a == b);
        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        uint256 c = a / b;
         
        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

interface token {
    function mint(address _to, uint256 _amount) public returns (bool);     
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool);
    function transferOwnership(address newOwner) public;
    
}

 
contract Ownable {
    address public owner;


    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);


     
    function Ownable() public {
        owner = msg.sender;
    }

     
    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0));
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

}


 
contract Crowdsale {
    using SafeMath for uint256;

     
    token public tokenReward;

     
    uint256 public startTime;
    uint256 public endTime;

     
    address public wallet;

     
    uint256 public rate;

     
    uint256 public weiRaised;

     
    event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);


    function Crowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _token) public {
         
        require(_endTime >= _startTime);
        require(_rate > 0);
        require(_wallet != address(0));

         
        tokenReward = token(_token);
        startTime = _startTime;
        endTime = _endTime;
        rate = _rate;
        wallet = _wallet;
    }

     
     
     
     
     

     
     
    function forwardFunds() internal {
        wallet.transfer(msg.value);
    }

     
    function validPurchase() internal view returns (bool) {
        bool withinPeriod = now >= startTime && now <= endTime;
        bool nonZeroPurchase = msg.value != 0;
        return withinPeriod && nonZeroPurchase;
    }

     
    function hasEnded() public view returns (bool) {
        return now > endTime;
    }


}

 
contract RefundVault is Ownable {
    using SafeMath for uint256;

    enum State { Active, Refunding, Closed }

    mapping (address => uint256) public deposited;
    address public wallet;
    State public state;

    event Closed();
    event RefundsEnabled();
    event Refunded(address indexed beneficiary, uint256 weiAmount);

    function RefundVault(address _wallet) public {
        require(_wallet != address(0));
        wallet = _wallet;
        state = State.Active;
    }

    function deposit(address investor) onlyOwner public payable {
        require(state == State.Active);
        deposited[investor] = deposited[investor].add(msg.value);
    }

    function close() onlyOwner public {
        require(state == State.Active);
        state = State.Closed;
        emit Closed();
        wallet.transfer(this.balance);
    }

    function enableRefunds() onlyOwner public {
        require(state == State.Active);
        state = State.Refunding;
        emit RefundsEnabled();
    }

    function refund(address investor) public {
        require(state == State.Refunding);
        uint256 depositedValue = deposited[investor];
        deposited[investor] = 0;
        investor.transfer(depositedValue);
        emit Refunded(investor, depositedValue);
    }
}


 
contract FinalizableCrowdsale is Crowdsale, Ownable {
    using SafeMath for uint256;

    bool public isFinalized = false;

    event Finalized();

     
    function finalize() onlyOwner public {
        require(!isFinalized);
        require(hasEnded());

        finalization();
        emit Finalized();

        isFinalized = true;
    }

   
    function finalization() internal {
    }
}
 
contract RefundableCrowdsale is FinalizableCrowdsale {
    using SafeMath for uint256;

     
    uint256 public goal;

     
    RefundVault public vault;

    function RefundableCrowdsale(uint256 _goal) public {
        require(_goal > 0);
        vault = new RefundVault(wallet);
        goal = _goal;
    }

     
     
     
    function forwardFunds() internal {
        vault.deposit.value(msg.value)(msg.sender);
    }

     
    function claimRefund() public {
        require(isFinalized);
        require(!goalReached());

        vault.refund(msg.sender);
    }

     
    function finalization() internal {
        if (!goalReached()) {
            vault.enableRefunds(); 
        } 

        super.finalization();
    }

    function goalReached() public view returns (bool) {
        return weiRaised >= goal;
    }

}

 
contract CappedCrowdsale is Crowdsale {
    using SafeMath for uint256;

    uint256 public cap;

    function CappedCrowdsale(uint256 _cap) public {
        require(_cap > 0);
        cap = _cap;
    }


     
     
    function hasEnded() public view returns (bool) {
        bool capReached = weiRaised >= cap;
        return super.hasEnded() || capReached;
    }

}

contract ControlledAccess is Ownable {
    address public signer;
    event SignerTransferred(address indexed previousSigner, address indexed newSigner);

      
    modifier onlySigner() {
        require(msg.sender == signer);
        _;
    }
     

    function transferSigner(address newSigner) public onlyOwner {
        require(newSigner != address(0));
        emit SignerTransferred(signer, newSigner);
        signer = newSigner;
    }
    
    
    modifier onlyValidAccess(uint8 _v, bytes32 _r, bytes32 _s) 
    {
        require(isValidAccessMessage(msg.sender,_v,_r,_s) );
        _;
    }
 
     
    function isValidAccessMessage(
        address _add,
        uint8 _v, 
        bytes32 _r, 
        bytes32 _s) 
        view public returns (bool)
    {
        bytes32 hash = keccak256(this, _add);
        return signer == ecrecover(
            keccak256("\x19Ethereum Signed Message:\n32", hash),
            _v,
            _r,
            _s
        );
    }
}

contract ElepigCrowdsale is CappedCrowdsale, RefundableCrowdsale, ControlledAccess {
    using SafeMath for uint256;
    
     
     
    enum CrowdsaleStage { PreICO, ICO1, ICO2, ICO3, ICO4 }  
    CrowdsaleStage public stage = CrowdsaleStage.PreICO;  
     

    address public community;    

   
     
     
    uint256 public totalTokensForSale = 150000000000000000000000000;   
    uint256 public totalTokensForSaleDuringPreICO = 30000000000000000000000000;  
    uint256 public totalTokensForSaleDuringICO1 = 37500000000000000000000000;    
    uint256 public totalTokensForSaleDuringICO2 = 37500000000000000000000000;    
    uint256 public totalTokensForSaleDuringICO3 = 30000000000000000000000000;    
    uint256 public totalTokensForSaleDuringICO4 = 15000000000000000000000000;    
   

     
     
    
     
    uint256 public totalWeiRaisedDuringPreICO;
    uint256 public totalWeiRaisedDuringICO1;
    uint256 public totalWeiRaisedDuringICO2;
    uint256 public totalWeiRaisedDuringICO3;
    uint256 public totalWeiRaisedDuringICO4;
    uint256 public totalWeiRaised;


     
    uint256 public totalTokensPreICO;
    uint256 public totalTokensICO1;
    uint256 public totalTokensICO2;
    uint256 public totalTokensICO3;
    uint256 public totalTokensICO4;
    uint256 public tokensMinted;
    

    uint256 public airDropsClaimed = 0;
     

    mapping (address => bool) public airdrops;
    mapping (address => bool) public blacklist;
    
    
     
    event EthTransferred(string text);
    event EthRefunded(string text);
   


     
     
    function ElepigCrowdsale(
        uint256 _startTime,
        uint256 _endTime,
        uint256 _rate,
        address _wallet,
        uint256 _goal,
        uint256 _cap,
        address _communityAddress,
        address _token,
        address _signer
    ) 
    CappedCrowdsale(_cap) FinalizableCrowdsale() RefundableCrowdsale(_goal) Crowdsale( _startTime, _endTime,  _rate, _wallet, _token) public {
        require(_goal <= _cap);    
        require(_signer != address(0));
        require(_communityAddress != address(0));
        require(_token != address(0));


        community = _communityAddress;  
        signer = _signer;  

        
    }
    

   
   
   

   
    function setCrowdsaleStage(uint value) public onlyOwner {
        require(value <= 4);
        if (uint(CrowdsaleStage.PreICO) == value) {
            rate = 2380;  
            stage = CrowdsaleStage.PreICO;
        } else if (uint(CrowdsaleStage.ICO1) == value) {
            rate = 2040;  
            stage = CrowdsaleStage.ICO1;
        }
        else if (uint(CrowdsaleStage.ICO2) == value) {
            rate = 1785;  
            stage = CrowdsaleStage.ICO2;
        }
        else if (uint(CrowdsaleStage.ICO3) == value) {
            rate = 1587;  
            stage = CrowdsaleStage.ICO3;
        }
        else if (uint(CrowdsaleStage.ICO4) == value) {
            rate = 1503;  
            stage = CrowdsaleStage.ICO4;
        }
    }


     
    function setCurrentRate(uint256 _rate) private {
        rate = _rate;
    }    
     

     
     
     


     
    function addBlacklistAddress (address _address) public onlyOwner {
        blacklist[_address] = true;
    }
    
     
    function removeBlacklistAddress (address _address) public onlyOwner {
        blacklist[_address] = false;
    } 

     


     
     
    function donate(uint8 _v, bytes32 _r, bytes32 _s) 
    onlyValidAccess(_v,_r,_s) public payable{
        require(msg.value >= 150000000000000000);  
        require(blacklist[msg.sender] == false);  
        
        require(validPurchase());  
        
        uint256 tokensThatWillBeMintedAfterPurchase = msg.value.mul(rate);

         
        if ((stage == CrowdsaleStage.PreICO) && (totalTokensPreICO + tokensThatWillBeMintedAfterPurchase > totalTokensForSaleDuringPreICO)) {
            msg.sender.transfer(msg.value);  
            emit EthRefunded("PreICO Limit Hit");
            return;
        } 
        if ((stage == CrowdsaleStage.ICO1) && (totalTokensICO1 + tokensThatWillBeMintedAfterPurchase > totalTokensForSaleDuringICO1)) {
            msg.sender.transfer(msg.value);  
            emit EthRefunded("ICO1 Limit Hit");
            return;

        }         
        if ((stage == CrowdsaleStage.ICO2) && (totalTokensICO2 + tokensThatWillBeMintedAfterPurchase > totalTokensForSaleDuringICO2)) {
            msg.sender.transfer(msg.value);  
            emit EthRefunded("ICO2 Limit Hit");
            return;

        }  
        if ((stage == CrowdsaleStage.ICO3) && (totalTokensICO3 + tokensThatWillBeMintedAfterPurchase > totalTokensForSaleDuringICO3)) {
            msg.sender.transfer(msg.value);  
            emit EthRefunded("ICO3 Limit Hit");
            return;        
        } 

        if ((stage == CrowdsaleStage.ICO4) && (totalTokensICO4 + tokensThatWillBeMintedAfterPurchase > totalTokensForSaleDuringICO4)) {
            msg.sender.transfer(msg.value);  
            emit EthRefunded("ICO4 Limit Hit");
            return;
        } else {                
             
            uint256 tokens = msg.value.mul(rate);
            weiRaised = weiRaised.add(msg.value);          

             
            tokenReward.mint(msg.sender, tokens);
            emit TokenPurchase(msg.sender, msg.sender, msg.value, tokens);
            forwardFunds();            
             

            if (stage == CrowdsaleStage.PreICO) {
                totalWeiRaisedDuringPreICO = totalWeiRaisedDuringPreICO.add(msg.value);
                totalTokensPreICO = totalTokensPreICO.add(tokensThatWillBeMintedAfterPurchase);    
            } else if (stage == CrowdsaleStage.ICO1) {
                totalWeiRaisedDuringICO1 = totalWeiRaisedDuringICO1.add(msg.value);
                totalTokensICO1 = totalTokensICO1.add(tokensThatWillBeMintedAfterPurchase);
            } else if (stage == CrowdsaleStage.ICO2) {
                totalWeiRaisedDuringICO2 = totalWeiRaisedDuringICO2.add(msg.value);
                totalTokensICO2 = totalTokensICO2.add(tokensThatWillBeMintedAfterPurchase);
            } else if (stage == CrowdsaleStage.ICO3) {
                totalWeiRaisedDuringICO3 = totalWeiRaisedDuringICO3.add(msg.value);
                totalTokensICO3 = totalTokensICO3.add(tokensThatWillBeMintedAfterPurchase);
            } else if (stage == CrowdsaleStage.ICO4) {
                totalWeiRaisedDuringICO4 = totalWeiRaisedDuringICO4.add(msg.value);
                totalTokensICO4 = totalTokensICO4.add(tokensThatWillBeMintedAfterPurchase);
            }

        }
         
        tokensMinted = tokensMinted.add(tokensThatWillBeMintedAfterPurchase);      
        
    }

     
    function () external payable {
        revert();
    }

    function forwardFunds() internal {
         
        if (goalReached()) {
            wallet.transfer(msg.value);
            emit EthTransferred("forwarding funds to wallet");
        } else  {
            emit EthTransferred("forwarding funds to refundable vault");
            super.forwardFunds();
        }
    }
  
      
    function airdropTokens(address _from, address[] _recipient, bool _premium) public onlyOwner {
        uint airdropped;
        uint tokens;

        if(_premium == true) {
            tokens = 500000000000000000000;
        } else {
            tokens = 50000000000000000000;
        }

        for(uint256 i = 0; i < _recipient.length; i++)
        {
            if (!airdrops[_recipient[i]]) {
                airdrops[_recipient[i]] = true;
                require(tokenReward.transferFrom(_from, _recipient[i], tokens));
                airdropped = airdropped.add(tokens);
            }
        }
        
        airDropsClaimed = airDropsClaimed.add(airdropped);
    }

   
   

    function finish() public onlyOwner {

        require(!isFinalized);
        
        if(tokensMinted < totalTokensForSale) {

            uint256 unsoldTokens = totalTokensForSale - tokensMinted;            
            tokenReward.mint(community, unsoldTokens);
            
        }
             
        finalize();
    } 

     
    function releaseVault() public onlyOwner {
        require(goalReached());
        vault.close();
    }

     
    function transferTokenOwnership(address _newOwner) public onlyOwner {
        tokenReward.transferOwnership(_newOwner);
    }
   

  
}
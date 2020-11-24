 

 
 
 
 
 
 
 
 
 
 
 
 

 
 

pragma solidity ^0.4.21;

library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
    if (a == 0) {
      return 0;
    }
    c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256 c) {
    c = a + b;
    assert(c >= a);
    return c;
  }
}

contract MUSystem {
    
    using SafeMath for uint;
    
    string public constant name = "Mutual Uniting System";
    string public constant symbol = "MUS";
    uint public constant decimals = 15;
    uint public totalSupply;
    address private creatorOwner;
    address private userAddr;
    mapping (address => uint) balances;
    struct UserWhoBuy {
        uint UserAmt;
        uint UserTokenObtain;
        uint UserBuyDate;
        uint UserBuyFirstDate;
        uint UserBuyTokenPackNum;
        uint UserFirstAmt;
        uint UserContinued;
        uint UserTotalAmtDepositCurrentPack;
    }
    mapping (address => UserWhoBuy) usersWhoBuy;
    address[] private userWhoBuyDatas;
    struct UserWhoSell {
        uint UserAmtWithdrawal;
        uint UserTokenSell;
        uint UserSellDate;
        uint UserSellTokenPackNum;
        uint UserTotalAmtWithdrawal;
        uint UserTotalAmtWithdrawalCurrentPack;
    }
    mapping (address => UserWhoSell) usersWhoSell;
    address[] private userWhoSellDatas;

 
 
 
 
 

    uint private CoMargin = 101; 
    uint private CoOverlap = 110; 
    uint private Disparity = 70; 
    bool private DisparityMode;
    uint private RestartModeDate;
    bool private RestartMode;
    uint private PackVolume = 50;  
    uint private FirstPackTokenPriceSellout = 50;    
    uint private BigAmt = 250 * 1 ether; 
    bool private feeTransfered;
    uint private PrevPrevPackTokenPriceSellout;
    uint private PrevPackTokenPriceSellout;
    uint private PrevPackTokenPriceBuyout; 
    uint private PrevPackDelta; 
    uint private PrevPackCost;
    uint private PrevPackTotalAmt;
    uint private CurrentPackYield;
    uint private CurrentPackDelta;
    uint private CurrentPackCost;
    uint private CurrentPackTotalToPay;
    uint private CurrentPackTotalAmt;
    uint private CurrentPackRestAmt;
    uint private CurrentPackFee;
    uint private CurrentPackTotalToPayDisparity;
    uint private CurrentPackNumber; 
    uint private CurrentPackStartDate; 
    uint private CurrentPackTokenPriceSellout;  
    uint private CurrentPackTokenPriceBuyout;
    uint private CurrentPackTokenAvailablePercent;
    uint private NextPackTokenPriceBuyout; 
    uint private NextPackYield; 
    uint private NextPackDelta;
    uint private userContinued;
    uint private userAmt; 
    uint private userFirstAmt;
    uint private userTotalAmtDepositCurrentPack;
    uint private userBuyFirstDate;
    uint private userTotalAmtWithdrawal;
    uint private userTotalAmtWithdrawalCurrentPack;
    uint private UserTokensReturn;
    bool private returnTokenInCurrentPack;
    uint private withdrawAmtToCurrentPack;
    uint private withdrawAmtAboveCurrentPack;
    uint private UserTokensReturnToCurrentPack;
    uint private UserTokensReturnAboveCurrentPack;
    uint private bonus;
    uint private userAmtOverloadToSend;

 
 
 

    constructor () public payable {
        creatorOwner = msg.sender;
        PackVolume = (10 ** decimals).mul(PackVolume);
        DisparityMode = false;
        RestartMode = false;
        CurrentPackNumber = 1; 
        CurrentPackStartDate = now;
        mint(PackVolume);
        packSettings(CurrentPackNumber);
    }

 

    function addUserWhoBuy (
    address _address, 
    uint _UserAmt, 
    uint _UserTokenObtain, 
    uint _UserBuyDate,
    uint _UserBuyFirstDate,
    uint _UserBuyTokenPackNum,
    uint _UserFirstAmt,
    uint _UserContinued,
    uint _UserTotalAmtDepositCurrentPack) internal {
        UserWhoBuy storage userWhoBuy = usersWhoBuy[_address];
        userWhoBuy.UserAmt = _UserAmt;
        userWhoBuy.UserTokenObtain = _UserTokenObtain;
        userWhoBuy.UserBuyDate = _UserBuyDate;
        userWhoBuy.UserBuyFirstDate = _UserBuyFirstDate;
        userWhoBuy.UserBuyTokenPackNum = _UserBuyTokenPackNum;
        userWhoBuy.UserFirstAmt = _UserFirstAmt;
        userWhoBuy.UserContinued = _UserContinued;
        userWhoBuy.UserTotalAmtDepositCurrentPack = _UserTotalAmtDepositCurrentPack;
        userWhoBuyDatas.push(_address) -1;
    }
 

    function addUserWhoSell (
    address _address, 
    uint _UserAmtWithdrawal, 
    uint _UserTokenSell, 
    uint _UserSellDate,
    uint _UserSellTokenPackNum,
    uint _UserTotalAmtWithdrawal,
    uint _UserTotalAmtWithdrawalCurrentPack) internal {
        UserWhoSell storage userWhoSell = usersWhoSell[_address];
        userWhoSell.UserAmtWithdrawal = _UserAmtWithdrawal;
        userWhoSell.UserTokenSell = _UserTokenSell;
        userWhoSell.UserSellDate = _UserSellDate;
        userWhoSell.UserSellTokenPackNum = _UserSellTokenPackNum;
        userWhoSell.UserTotalAmtWithdrawal = _UserTotalAmtWithdrawal; 
        userWhoSell.UserTotalAmtWithdrawalCurrentPack = _UserTotalAmtWithdrawalCurrentPack;
        userWhoSellDatas.push(_address) -1;
    }

 
 
 
 
 

    function packSettings (uint _currentPackNumber) internal {
        CurrentPackNumber = _currentPackNumber;
        if(CurrentPackNumber == 1){
            PrevPackDelta = 0;
            PrevPackCost = 0;
            PrevPackTotalAmt = 0;
            CurrentPackStartDate = now;
            CurrentPackTokenPriceSellout = FirstPackTokenPriceSellout;
            CurrentPackTokenPriceBuyout = FirstPackTokenPriceSellout; 
            CurrentPackCost = PackVolume.mul(CurrentPackTokenPriceSellout);
            CurrentPackTotalToPay = 0;
            CurrentPackTotalToPayDisparity = 0;
            CurrentPackYield = 0;
            CurrentPackDelta = 0;
            CurrentPackTotalAmt = CurrentPackCost;
            CurrentPackFee = 0;
            CurrentPackRestAmt = CurrentPackCost.sub(CurrentPackTotalToPay);
            if (FirstPackTokenPriceSellout == 50){NextPackTokenPriceBuyout = 60;}else{NextPackTokenPriceBuyout = FirstPackTokenPriceSellout+5;}
        }
        if(CurrentPackNumber == 2){
            PrevPrevPackTokenPriceSellout = 0;
            PrevPackTokenPriceSellout = CurrentPackTokenPriceSellout;
            PrevPackTokenPriceBuyout = CurrentPackTokenPriceBuyout;
            PrevPackDelta = CurrentPackDelta;
            PrevPackCost = CurrentPackCost;
            PrevPackTotalAmt = CurrentPackTotalAmt;
            CurrentPackYield = 0;
            CurrentPackDelta = 0;
            NextPackTokenPriceBuyout = PrevPackTokenPriceSellout.mul(CoOverlap).div(100);
            NextPackYield = NextPackTokenPriceBuyout.sub(PrevPackTokenPriceSellout);
            NextPackDelta = NextPackYield;
            CurrentPackTokenPriceSellout = NextPackTokenPriceBuyout.add(NextPackDelta);
            CurrentPackTokenPriceBuyout = CurrentPackTokenPriceSellout;
            CurrentPackCost = PackVolume.mul(CurrentPackTokenPriceSellout);
            CurrentPackTotalToPay = 0;
            CurrentPackTotalAmt = CurrentPackCost.add(PrevPackTotalAmt);
            CurrentPackFee = 0;
            CurrentPackTotalToPayDisparity = PrevPackCost.mul(Disparity).div(100);
            CurrentPackRestAmt = CurrentPackCost.sub(CurrentPackTotalToPay);
        }
        if(CurrentPackNumber > 2){
            PrevPackTokenPriceSellout = CurrentPackTokenPriceSellout;
            PrevPackTokenPriceBuyout = CurrentPackTokenPriceBuyout;
            PrevPackDelta = CurrentPackDelta;
            PrevPackCost = CurrentPackCost;
            PrevPackTotalAmt = CurrentPackTotalAmt;
            CurrentPackYield = NextPackYield;
            CurrentPackDelta = NextPackDelta;
            CurrentPackTokenPriceBuyout = NextPackTokenPriceBuyout;
            NextPackTokenPriceBuyout = PrevPackTokenPriceSellout.mul(CoOverlap);
            if(NextPackTokenPriceBuyout<=100){  
                NextPackTokenPriceBuyout=PrevPackTokenPriceSellout.mul(CoOverlap).div(100);
            }
            if(NextPackTokenPriceBuyout>100){ 
                NextPackTokenPriceBuyout=NextPackTokenPriceBuyout*10**3;
                NextPackTokenPriceBuyout=((NextPackTokenPriceBuyout/10000)+5)/10;
            }
            NextPackYield = NextPackTokenPriceBuyout.sub(PrevPackTokenPriceSellout);
            NextPackDelta = NextPackYield.mul(CoMargin);
            if(NextPackDelta <= 100){ 
                NextPackDelta = CurrentPackDelta.add(NextPackYield.mul(CoMargin).div(100));
            }
            if(NextPackDelta > 100){
                NextPackDelta = NextPackDelta*10**3;
                NextPackDelta = ((NextPackDelta/10000)+5)/10;
                NextPackDelta = CurrentPackDelta.add(NextPackDelta);
            }
            CurrentPackTokenPriceSellout = NextPackTokenPriceBuyout.add(NextPackDelta);
            CurrentPackCost = PackVolume.mul(CurrentPackTokenPriceSellout);
            CurrentPackTotalToPay = PackVolume.mul(CurrentPackTokenPriceBuyout);
            CurrentPackTotalToPayDisparity = PrevPackCost.mul(Disparity).div(100);
            CurrentPackRestAmt = CurrentPackCost.sub(CurrentPackTotalToPay);
            CurrentPackTotalAmt = CurrentPackRestAmt.add(PrevPackTotalAmt);
            CurrentPackFee = PrevPackTotalAmt.sub(CurrentPackTotalToPay).sub(CurrentPackTotalToPayDisparity);
        }
        CurrentPackTokenAvailablePercent = balances[address(this)].mul(100).div(PackVolume);
        emit NextPack(CurrentPackTokenPriceSellout, CurrentPackTokenPriceBuyout);
    }

 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 
 

    function aboutCurrentPack () public constant returns (uint availableTokens, uint availableTokensInPercentage, uint availableAmountToDepositInWei, uint tokenPriceSellout, uint tokenPriceBuyout){
        uint _availableTokens = balances[address(this)];
        uint _availableAmountToDepositInWei = _availableTokens.mul(CurrentPackTokenPriceSellout);
        return (_availableTokens, CurrentPackTokenAvailablePercent, _availableAmountToDepositInWei, CurrentPackTokenPriceSellout, CurrentPackTokenPriceBuyout);
    }

 
 

    function nextPack (uint _currentPackNumber) internal { 
        transferFee();
        feeTransfered = false;
        CurrentPackNumber=_currentPackNumber.add(1);
        CurrentPackStartDate = now;
        mint(PackVolume);
        packSettings(CurrentPackNumber);
    }

 
 
 
 
 
 
 
 

    function restart(bool _dm)internal{
        if(_dm==true){if(RestartMode==false){RestartMode=true;RestartModeDate=now;}
            else{if(now>RestartModeDate+14*1 days){RestartMode=false;DisparityMode=false;nextPack(0);}}}
        else{if(RestartMode==true){RestartMode=false;RestartModeDate=0;}}
    }

 
 
 

    function transferFee()internal{
        if(CurrentPackNumber > 2 && feeTransfered == false){
            if(address(this).balance>=CurrentPackFee){
                creatorOwner.transfer(CurrentPackFee);
                feeTransfered = true;
            }
        }
    }

 
 

    function deposit() public payable returns (uint UserTokenObtain){ 
        require(msg.sender != 0x0 && msg.sender != 0);
        require(msg.value < BigAmt); 
        uint availableTokens = balances[address(this)];
        require(msg.value <= availableTokens.mul(CurrentPackTokenPriceSellout).add(availableTokens.mul(CurrentPackTokenPriceSellout).mul(10).div(100)).add(10*1 finney)); 
        require(msg.value.div(CurrentPackTokenPriceSellout) > 0);
        userAddr = msg.sender;
        userAmt = msg.value;
        if(usersWhoBuy[userAddr].UserBuyTokenPackNum == CurrentPackNumber){
            userTotalAmtDepositCurrentPack = usersWhoBuy[userAddr].UserTotalAmtDepositCurrentPack;
        }
        else{
            userTotalAmtDepositCurrentPack = 0;
        }
        if(usersWhoBuy[userAddr].UserBuyTokenPackNum == CurrentPackNumber){
            require(userTotalAmtDepositCurrentPack.add(userAmt) < BigAmt);
        }

 
 
 
 
 
 

        if(usersWhoSell[userAddr].UserSellTokenPackNum == CurrentPackNumber){
            uint penalty = usersWhoSell[userAddr].UserTotalAmtWithdrawalCurrentPack.mul(5).div(100);
            userAmt = userAmt.sub(penalty);
            require(userAmt.div(CurrentPackTokenPriceSellout) > 0);
            penalty=0;
        }
        UserTokenObtain = userAmt.div(CurrentPackTokenPriceSellout);
        bonus = 0;

 
 
 
 
 

        if(userAmt >= 100*1 finney){
            if(now <= (CurrentPackStartDate + 1*1 days)){
                bonus = UserTokenObtain.mul(75).div(10000);
            }
            if(now > (CurrentPackStartDate + 1*1 days) && now <= (CurrentPackStartDate + 2*1 days)){
                bonus = UserTokenObtain.mul(50).div(10000);
            }
            if(now > (CurrentPackStartDate + 2*1 days) && now <= (CurrentPackStartDate + 3*1 days)){
                bonus = UserTokenObtain.mul(25).div(10000);
            }
        }

 
 
 
 
 
 

        if(userContinued > 4 && now > (userBuyFirstDate + 1 * 1 weeks)){
            bonus = bonus.add(UserTokenObtain.mul(1).div(100));
        }
        UserTokenObtain = UserTokenObtain.add(bonus);  
        if(UserTokenObtain > availableTokens){
            userAmtOverloadToSend = CurrentPackTokenPriceSellout.mul(UserTokenObtain.sub(availableTokens)); 
            transfer(address(this), userAddr, availableTokens);
            UserTokenObtain = availableTokens;
            if(address(this).balance>=userAmtOverloadToSend){
                userAddr.transfer(userAmtOverloadToSend);
            }
        }                
        else{                 
            transfer(address(this), userAddr, UserTokenObtain);
        }
        if(usersWhoBuy[userAddr].UserBuyTokenPackNum == 0){
            userFirstAmt = userAmt;
            userBuyFirstDate = now;
        }
        else{
            userFirstAmt = usersWhoBuy[userAddr].UserFirstAmt;
            userBuyFirstDate = usersWhoBuy[userAddr].UserBuyFirstDate;
        }
        if(usersWhoBuy[userAddr].UserContinued == 0){
            userContinued = 1;
        }
        else{
            if(usersWhoBuy[userAddr].UserBuyTokenPackNum == CurrentPackNumber.sub(1)){
                userContinued = userContinued.add(1);
            }
            else{
                userContinued = 1;
            }
        }
        userTotalAmtDepositCurrentPack = userTotalAmtDepositCurrentPack.add(userAmt);
        addUserWhoBuy(userAddr, userAmt, UserTokenObtain, now, userBuyFirstDate, CurrentPackNumber, userFirstAmt, userContinued, userTotalAmtDepositCurrentPack);
        CurrentPackTokenAvailablePercent = balances[address(this)].mul(100).div(PackVolume);
        bonus = 0;
        availableTokens = 0;
        userAmtOverloadToSend = 0;
        userAddr = 0;
        userAmt = 0;
        restart(false);
        DisparityMode = false;

 

        if(balances[address(this)] == 0){nextPack(CurrentPackNumber);}
        return UserTokenObtain;
    } 

 

    function withdraw(uint WithdrawAmount, uint WithdrawTokens) public returns (uint withdrawAmt){
        require(msg.sender != 0x0 && msg.sender != 0);
        require(WithdrawTokens > 0 || WithdrawAmount > 0);
        require(WithdrawTokens<=balances[msg.sender]); 
        require(WithdrawAmount.mul(1 finney)<=balances[msg.sender].mul(CurrentPackTokenPriceSellout).add(balances[msg.sender].mul(CurrentPackTokenPriceSellout).mul(5).div(100)));

 
 

        if(RestartMode==true){restart(true);}
        if(address(this).balance<=CurrentPackTotalToPayDisparity){
            DisparityMode=true;}else{DisparityMode=false;}

 
 
 
 

        userTotalAmtWithdrawal = usersWhoSell[msg.sender].UserTotalAmtWithdrawal;
        if(usersWhoSell[msg.sender].UserSellTokenPackNum == CurrentPackNumber){
            userTotalAmtWithdrawalCurrentPack = usersWhoSell[msg.sender].UserTotalAmtWithdrawalCurrentPack;
        }
        else{
            userTotalAmtWithdrawalCurrentPack = 0;
        }
        if(usersWhoBuy[msg.sender].UserBuyTokenPackNum == CurrentPackNumber && userTotalAmtWithdrawalCurrentPack < usersWhoBuy[msg.sender].UserTotalAmtDepositCurrentPack){
            returnTokenInCurrentPack = true;
            withdrawAmtToCurrentPack = usersWhoBuy[msg.sender].UserTotalAmtDepositCurrentPack.sub(userTotalAmtWithdrawalCurrentPack);
        }
        else{ 
            returnTokenInCurrentPack = false;
        }
        if(WithdrawAmount > 0){
            withdrawAmt = WithdrawAmount.mul(1 finney);
            if(returnTokenInCurrentPack == true){
                UserTokensReturnToCurrentPack = withdrawAmtToCurrentPack.div(CurrentPackTokenPriceSellout);
                if(withdrawAmt>withdrawAmtToCurrentPack){ 
                    withdrawAmtAboveCurrentPack = withdrawAmt.sub(withdrawAmtToCurrentPack);
                    UserTokensReturnAboveCurrentPack = withdrawAmtAboveCurrentPack.div(CurrentPackTokenPriceBuyout);
                } 
                else{
                    withdrawAmtToCurrentPack = withdrawAmt;
                    UserTokensReturnToCurrentPack = withdrawAmtToCurrentPack.div(CurrentPackTokenPriceSellout);
                    withdrawAmtAboveCurrentPack = 0;
                    UserTokensReturnAboveCurrentPack = 0;
                }
            }
            else{
                withdrawAmtToCurrentPack = 0;
                UserTokensReturnToCurrentPack = 0;
                withdrawAmtAboveCurrentPack = withdrawAmt;
                UserTokensReturnAboveCurrentPack = withdrawAmtAboveCurrentPack.div(CurrentPackTokenPriceBuyout);
            }
        }
        else{
            UserTokensReturn = WithdrawTokens;
            if(returnTokenInCurrentPack == true){
                UserTokensReturnToCurrentPack = withdrawAmtToCurrentPack.div(CurrentPackTokenPriceSellout);
                if(UserTokensReturn>UserTokensReturnToCurrentPack){
                    UserTokensReturnAboveCurrentPack = UserTokensReturn.sub(UserTokensReturnToCurrentPack);
                    withdrawAmtAboveCurrentPack = UserTokensReturnAboveCurrentPack.mul(CurrentPackTokenPriceBuyout);
                }
                else{
                    withdrawAmtToCurrentPack = UserTokensReturn.mul(CurrentPackTokenPriceSellout);
                    UserTokensReturnToCurrentPack = UserTokensReturn;
                    withdrawAmtAboveCurrentPack = 0;
                    UserTokensReturnAboveCurrentPack = 0;
                }
            }
            else{
                withdrawAmtToCurrentPack = 0;
                UserTokensReturnToCurrentPack = 0;
                UserTokensReturnAboveCurrentPack = UserTokensReturn;
                withdrawAmtAboveCurrentPack = UserTokensReturnAboveCurrentPack.mul(CurrentPackTokenPriceBuyout);
            }    
        }
        withdrawAmt = withdrawAmtToCurrentPack.add(withdrawAmtAboveCurrentPack);

 
 
 

        if(balances[address(this)]<=(PackVolume.mul(10).div(100))){
            withdrawAmtAboveCurrentPack = withdrawAmtAboveCurrentPack.add(withdrawAmt.mul(1).div(100));
        }

 
 
 
 
 
 
 

        if(address(this).balance<CurrentPackTotalToPayDisparity || withdrawAmt > address(this).balance || DisparityMode == true){
            uint disparityAmt = usersWhoBuy[msg.sender].UserFirstAmt.mul(Disparity).div(100);
            if(userTotalAmtWithdrawal >= disparityAmt){
                withdrawAmtAboveCurrentPack = 0;
                UserTokensReturnAboveCurrentPack = 0;
            }
            else{
                if(withdrawAmtAboveCurrentPack.add(userTotalAmtWithdrawal) >= disparityAmt){
                    withdrawAmtAboveCurrentPack = disparityAmt.sub(userTotalAmtWithdrawal);
                    UserTokensReturnAboveCurrentPack = withdrawAmtAboveCurrentPack.div(CurrentPackTokenPriceBuyout);
                }
            }
            DisparityMode = true;
            if(CurrentPackNumber>2){restart(true);}
        }
        if(withdrawAmt>address(this).balance){
            withdrawAmt = address(this).balance;
            withdrawAmtAboveCurrentPack = address(this).balance.sub(withdrawAmtToCurrentPack);
            UserTokensReturnAboveCurrentPack = withdrawAmtAboveCurrentPack.div(CurrentPackTokenPriceBuyout);
            if(CurrentPackNumber>2){restart(true);}
        }
        withdrawAmt = withdrawAmtToCurrentPack.add(withdrawAmtAboveCurrentPack);
        UserTokensReturn = UserTokensReturnToCurrentPack.add(UserTokensReturnAboveCurrentPack);
        require(UserTokensReturn<=balances[msg.sender]); 
        transfer(msg.sender, address(this), UserTokensReturn);
        msg.sender.transfer(withdrawAmt);
        userTotalAmtWithdrawal = userTotalAmtWithdrawal.add(withdrawAmt);
        userTotalAmtWithdrawalCurrentPack = userTotalAmtWithdrawalCurrentPack.add(withdrawAmt);
        addUserWhoSell(msg.sender, withdrawAmt, UserTokensReturn, now, CurrentPackNumber, userTotalAmtWithdrawal, userTotalAmtWithdrawalCurrentPack);
        CurrentPackTokenAvailablePercent = balances[address(this)].mul(100).div(PackVolume);
        withdrawAmtToCurrentPack = 0;
        withdrawAmtAboveCurrentPack = 0;
        UserTokensReturnToCurrentPack = 0;
        UserTokensReturnAboveCurrentPack = 0;
        return withdrawAmt;
    }

 
 
 
 

    function transfer(address _from, address _to, uint _value) internal returns (bool success) {
        balances[_from] = balances[_from].sub(_value); 
        if(_to == address(this)){ 
            if(returnTokenInCurrentPack == true){
                balances[_to] = balances[_to].add(UserTokensReturnToCurrentPack);
            }
            else{
                balances[_to] = balances[_to];
            }
            totalSupply = totalSupply.sub(UserTokensReturnAboveCurrentPack);
        }
        else{
            balances[_to] = balances[_to].add(_value);
        }
        emit Transfer(_from, _to, _value); 
        return true;
    }  

 

    function balanceOf(address tokenOwner) public constant returns (uint balance) {
        return balances[tokenOwner];
    }

 

    function mint(uint _value) internal returns (bool) {
        balances[address(this)] = balances[address(this)].add(_value);
        totalSupply = totalSupply.add(_value);
        return true;
    }

    event Transfer(address indexed _from, address indexed _to, uint _value);
    event NextPack(uint indexed CurrentPackTokenPriceSellout, uint indexed CurrentPackTokenPriceBuyout);
}
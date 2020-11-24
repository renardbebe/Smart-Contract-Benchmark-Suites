 

 

pragma solidity ^0.5.0;

 
library SafeMath {
     
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

     
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");
        uint256 c = a - b;

        return c;
    }

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
         
         
         
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

     
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
         
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;
         

        return c;
    }

     
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b != 0, "SafeMath: modulo by zero");
        return a % b;
    }
}

 

pragma solidity ^0.5.0;

 
contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

     
    constructor () internal {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

     
    function owner() public view returns (address) {
        return _owner;
    }

     
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

     
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

     
    function renounceOwnership() public onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

     
    function transferOwnership(address newOwner) public onlyOwner {
        _transferOwnership(newOwner);
    }

     
    function _transferOwnership(address newOwner) internal {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

 

pragma solidity ^0.5.0;

 
contract ReentrancyGuard {
     
    uint256 private _guardCounter;

    constructor () internal {
         
         
        _guardCounter = 1;
    }

     
    modifier nonReentrant() {
        _guardCounter += 1;
        uint256 localCounter = _guardCounter;
        _;
        require(localCounter == _guardCounter, "ReentrancyGuard: reentrant call");
    }
}

 

pragma solidity ^0.5.0;

 
interface IERC20 {
     
    function totalSupply() external view returns (uint256);

     
    function balanceOf(address account) external view returns (uint256);

     
    function transfer(address recipient, uint256 amount) external returns (bool);

     
    function allowance(address owner, address spender) external view returns (uint256);

     
    function approve(address spender, uint256 amount) external returns (bool);

     
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

     
    event Transfer(address indexed from, address indexed to, uint256 value);

     
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

 

pragma solidity ^0.5.8;

 
interface IAllocationStrategy {

     
    function underlying() external view returns (address);

     
    function exchangeRateStored() external view returns (uint256);

     
    function accrueInterest() external returns (bool);

     
    function investUnderlying(uint256 investAmount) external returns (uint256);

     
    function redeemUnderlying(uint256 redeemAmount) external returns (uint256);

}

 

pragma solidity ^0.5.8;
pragma experimental ABIEncoderV2;



 
contract IRToken is IERC20 {


     
    struct GlobalStats {
         
        uint256 totalSupply;
         
        uint256 totalSavingsAmount;
    }

     
    struct AccountStats {
         
        uint256 cumulativeInterest;
    }


     
     
     
     
    function mint(uint256 mintAmount) external returns (bool);

     
    function mintWithSelectedHat(uint256 mintAmount, uint256 hatID) external returns (bool);

     
    function mintWithNewHat(uint256 mintAmount,
        address[] calldata recipients,
        uint32[] calldata proportions) external returns (bool);

     
    function redeem(uint256 redeemTokens) external returns (bool);

     
    function redeemAndTransfer(address redeemTo, uint256 redeemTokens) external returns (bool);

     
    function createHat(
        address[] calldata recipients,
        uint32[] calldata proportions,
        bool doChangeHat) external returns (uint256 hatID);

     
    function changeHat(uint256 hatID) external;

     
    function payInterest(address owner) external returns (bool);

     
     
     
     
    function getMaximumHatID() external view returns (uint256 hatID);

     
    function getHatByAddress(address owner) external view
        returns (
            uint256 hatID,
            address[] memory recipients,
            uint32[] memory proportions);

     
    function getHatByID(uint256 hatID) external view
        returns (
            address[] memory recipients,
            uint32[] memory proportions);

     
    function receivedSavingsOf(address owner) external view returns (uint256 amount);

     
    function receivedLoanOf(address owner) external view returns (uint256 amount);

     
    function interestPayableOf(address owner) external view returns (uint256 amount);

     
     
     
     
    function getCurrentSavingStrategy() external view returns (address);

     
    function getSavingAssetBalance() external view returns (uint256 nAmount, uint256 sAmount);

     
    function getGlobalStats() external view returns (GlobalStats memory);

     
    function getAccountStats(address owner) external view returns (AccountStats memory);


     
     
     
     
    function changeAllocationStrategy(IAllocationStrategy allocationStrategy) external;

     
     
     
     
    event Mint(address indexed minter, uint256 mintAmount);

     
    event Redeem(address indexed redeemer, address indexed redeemTo, uint256 redeemAmount);

     
    event InterestPaid(address indexed recipient, uint256 interestAmount);

     
    event HatCreated(uint256 indexed hatID);

     
    event HatChanged(address indexed account, uint256 indexed hatID);
}

 

pragma solidity ^0.5.8;






 
contract RToken is IRToken, Ownable, ReentrancyGuard {

    using SafeMath for uint256;

    uint256 public constant SELF_HAT_ID = uint256(int256(-1));

    uint32 constant PROPORTION_BASE = 0xFFFFFFFF;

     
     
     

     
    struct Hat {
        address[] recipients;
        uint32[] proportions;
    }

     
    constructor(IAllocationStrategy allocationStrategy) public {
        ias = allocationStrategy;
        token = IERC20(ias.underlying());
         
        hats.push(Hat(new address[](0), new uint32[](0)));
    }

     
     
     

     
    string public name = "Redeemable DAI (rDAI ethberlin)";

     
    string public symbol = "rDAItest";

     
    uint256 public decimals = 18;

      
     uint256 public totalSupply;

     
    function balanceOf(address owner) external view returns (uint256) {
        return accounts[owner].rAmount;
    }

     
    function transfer(address dst, uint256 amount) external nonReentrant returns (bool) {
        return transferInternal(msg.sender, msg.sender, dst, amount);
    }

     
    function allowance(address owner, address spender) external view returns (uint256) {
        return transferAllowances[owner][spender];
    }

     
    function approve(address spender, uint256 amount) external returns (bool) {
        address src = msg.sender;
        transferAllowances[src][spender] = amount;
        emit Approval(src, spender, amount);
        return true;
    }

     
    function transferFrom(address src, address dst, uint256 amount) external nonReentrant returns (bool) {
        return transferInternal(msg.sender, src, dst, amount);
    }

     
     
     

     
    function mint(uint256 mintAmount) external nonReentrant returns (bool) {
        mintInternal(mintAmount);
        return true;
    }

     
    function mintWithSelectedHat(uint256 mintAmount, uint256 hatID) external returns (bool) {
        require(hatID == SELF_HAT_ID || hatID < hats.length, "Invalid hat ID");
        changeHatInternal(msg.sender, hatID);
        mintInternal(mintAmount);
        return true;
    }

     
    function mintWithNewHat(uint256 mintAmount,
        address[] calldata recipients,
        uint32[] calldata proportions) external nonReentrant returns (bool) {
        uint256 hatID = createHatInternal(recipients, proportions);
        changeHatInternal(msg.sender, hatID);

        mintInternal(mintAmount);

        return true;
    }

     
    function redeem(uint256 redeemTokens) external nonReentrant returns (bool) {
        redeemInternal(msg.sender, redeemTokens);
        return true;
    }

    function redeemAndTransfer(address redeemTo, uint256 redeemTokens) external returns (bool) {
        redeemInternal(redeemTo, redeemTokens);
        return true;
    }

      
    function createHat(
        address[] calldata recipients,
        uint32[] calldata proportions,
        bool doChangeHat) external nonReentrant returns (uint256 hatID) {
        hatID = createHatInternal(recipients, proportions);
        if (doChangeHat) {
            changeHatInternal(msg.sender, hatID);
        }
    }

     
    function changeHat(uint256 hatID) external nonReentrant {
        changeHatInternal(msg.sender, hatID);
    }

     
    function getMaximumHatID() external view returns (uint256 hatID) {
        return hats.length - 1;
    }

     
    function getHatByAddress(address owner) external view returns (
        uint256 hatID,
        address[] memory recipients,
        uint32[] memory proportions) {
        hatID = accounts[owner].hatID;
        if (hatID != 0 && hatID != SELF_HAT_ID) {
            Hat memory hat = hats[hatID];
            recipients = hat.recipients;
            proportions = hat.proportions;
        } else {
            recipients = new address[](0);
            proportions = new uint32[](0);
        }
    }

     
    function getHatByID(uint256 hatID) external view returns (
        address[] memory recipients,
        uint32[] memory proportions) {
        if (hatID != 0 && hatID != SELF_HAT_ID) {
            Hat memory hat = hats[hatID];
            recipients = hat.recipients;
            proportions = hat.proportions;
        } else {
            recipients = new address[](0);
            proportions = new uint32[](0);
        }
    }

     
    function receivedSavingsOf(address owner) external view returns (uint256 amount) {
        Account storage account = accounts[owner];
        uint256 rGross =
            account.sInternalAmount
            .mul(ias.exchangeRateStored())
            .div(savingAssetConversionRate);  
        return rGross;
    }

     
    function receivedLoanOf(address owner) external view returns (uint256 amount) {
        Account storage account = accounts[owner];
        return account.lDebt;
    }

     
    function interestPayableOf(address owner) external view returns (uint256 amount) {
        Account storage account = accounts[owner];
        return getInterestPayableOf(account);
    }

     
    function payInterest(address owner) external nonReentrant returns (bool) {
        Account storage account = accounts[owner];

        ias.accrueInterest();
        uint256 interestAmount = getInterestPayableOf(account);

        if (interestAmount > 0) {
            account.stats.cumulativeInterest = account.stats.cumulativeInterest.add(interestAmount);
            account.rInterest = account.rInterest.add(interestAmount);
            account.rAmount = account.rAmount.add(interestAmount);
            totalSupply = totalSupply.add(interestAmount);
            emit InterestPaid(owner, interestAmount);
            emit Transfer(address(this), owner, interestAmount);
        }
    }

     
    function getGlobalStats() external view returns (GlobalStats memory) {
        uint256 totalSavingsAmount;
        totalSavingsAmount +=
            savingAssetOrignalAmount
            .mul(ias.exchangeRateStored())
            .div(10 ** 18);
        return GlobalStats({
            totalSupply: totalSupply,
            totalSavingsAmount: totalSavingsAmount
        });
    }

     
    function getAccountStats(address owner) external view returns (AccountStats memory) {
        Account storage account = accounts[owner];
        return account.stats;
    }

     
    function getCurrentSavingStrategy() external view returns (address) {
        return address(ias);
    }

     
    function getSavingAssetBalance() external view
        returns (uint256 nAmount, uint256 sAmount) {
        sAmount = savingAssetOrignalAmount;
        nAmount = sAmount
            .mul(ias.exchangeRateStored())
            .div(10 ** 18);
    }

     
    function changeAllocationStrategy(IAllocationStrategy allocationStrategy) external {
        require(allocationStrategy.underlying() == address(token), "New strategy should have the same underlying asset");
        IAllocationStrategy oldIas = ias;
        ias = allocationStrategy;
         
        uint256 sOriginalBurned = oldIas.redeemUnderlying(totalSupply);
         
        token.transferFrom(msg.sender, address(this), totalSupply);
        token.approve(address(ias), totalSupply);
        uint256 sOriginalCreated = ias.investUnderlying(totalSupply);
         
         
         
        savingAssetConversionRate =
            sOriginalCreated
            .mul(10 ** 18)
            .div(sOriginalBurned);
    }

     
     
     

     
    IAllocationStrategy ias;

     
    IERC20 token;

     
    uint256 savingAssetOrignalAmount;

     
     
     
     
    uint256 savingAssetConversionRate = 10 ** 18;

     

     
    mapping(address => mapping(address => uint256)) transferAllowances;

     
    Hat[] hats;

     
    struct Account {
         
         
         
         
        uint256 hatID;
         
        uint256 rAmount;
         
        uint256 rInterest;
         
        mapping (address => uint256) lRecipients;
         
        uint256 lDebt;
         
        uint256 sInternalAmount;

         
        AccountStats stats;
    }

     
    mapping (address => Account) accounts;

     
    function transferInternal(address spender, address src, address dst, uint256 tokens) internal returns (bool) {
        require(src != dst, "src should not equal dst");
        require(accounts[src].rAmount >= tokens, "Not enough balance to transfer");

         
        uint256 startingAllowance = 0;
        if (spender == src) {
            startingAllowance = uint256(-1);
        } else {
            startingAllowance = transferAllowances[src][spender];
        }
        require(startingAllowance >= tokens, "Not enough allowance for transfer");

         
        uint256 allowanceNew = startingAllowance.sub(tokens);
        uint256 srcTokensNew = accounts[src].rAmount.sub(tokens);
        uint256 dstTokensNew = accounts[dst].rAmount.add(tokens);

         
         
         

         
        if (accounts[src].hatID != 0 && accounts[dst].hatID == 0) {
            changeHatInternal(dst, accounts[src].hatID);
        }

        accounts[src].rAmount = srcTokensNew;
        accounts[dst].rAmount = dstTokensNew;

         
        if (startingAllowance != uint256(-1)) {
            transferAllowances[src][spender] = allowanceNew;
        }

         
        uint256 sInternalAmountCollected = estimateAndRecollectLoans(src, tokens);
        distributeLoans(dst, tokens, sInternalAmountCollected);

         
        if (accounts[src].rInterest > accounts[src].rAmount) {
            accounts[src].rInterest = accounts[src].rAmount;
        }

         
        emit Transfer(src, dst, tokens);

        return true;
    }

     
    function mintInternal(uint256 mintAmount) internal {
        require(token.allowance(msg.sender, address(this)) >= mintAmount, "Not enough allowance");

        Account storage account = accounts[msg.sender];

         
        token.transferFrom(msg.sender, address(this), mintAmount);
        token.approve(address(ias), mintAmount);
        uint256 sOriginalCreated = ias.investUnderlying(mintAmount);

         
        totalSupply = totalSupply.add(mintAmount);
        account.rAmount = account.rAmount.add(mintAmount);

         
        savingAssetOrignalAmount += sOriginalCreated;

         
        uint256 sInternalCreated =
            sOriginalCreated
            .mul(savingAssetConversionRate)
            .div(10 ** 18);
        distributeLoans(msg.sender, mintAmount, sInternalCreated);

        emit Mint(msg.sender, mintAmount);
        emit Transfer(address(this), msg.sender, mintAmount);
    }

     
    function redeemInternal(address redeemTo, uint256 redeemAmount) internal {
        Account storage account = accounts[msg.sender];
        require(redeemAmount > 0, "Redeem amount cannot be zero");
        require(redeemAmount <= account.rAmount, "Not enough balance to redeem");

        uint256 sOriginalBurned = redeemAndRecollectLoans(msg.sender, redeemAmount);

         
        account.rAmount = account.rAmount.sub(redeemAmount);
        if (account.rInterest > account.rAmount) {
            account.rInterest = account.rAmount;
        }
        totalSupply = totalSupply.sub(redeemAmount);

         
        savingAssetOrignalAmount -= sOriginalBurned;

         
        token.transfer(redeemTo, redeemAmount);

        emit Transfer(msg.sender, address(this), redeemAmount);
        emit Redeem(msg.sender, redeemTo, redeemAmount);
    }

     
    function createHatInternal(
        address[] memory recipients,
        uint32[] memory proportions) internal returns (uint256 hatID) {
        uint i;

        require(recipients.length > 0, "Invalid hat: at least one recipient");
        require(recipients.length == proportions.length, "Invalid hat: length not matching");

         
        uint256 totalProportions = 0;
        for (i = 0; i < recipients.length; ++i) {
            require(proportions[i] > 0, "Invalid hat: proportion should be larger than 0");
            totalProportions += uint256(proportions[i]);
        }
        for (i = 0; i < proportions.length; ++i) {
            proportions[i] = uint32(
                uint256(proportions[i])
                * uint256(PROPORTION_BASE)
                / totalProportions);
        }

        hatID = hats.push(Hat(
            recipients,
            proportions
        )) - 1;
        emit HatCreated(hatID);
    }

     
    function changeHatInternal(address owner, uint256 hatID) internal {
        Account storage account = accounts[owner];
        if (account.rAmount > 0) {
            uint256 sInternalAmountCollected = estimateAndRecollectLoans(owner, account.rAmount);
            account.hatID = hatID;
            distributeLoans(owner, account.rAmount, sInternalAmountCollected);
        } else {
            account.hatID = hatID;
        }
        emit HatChanged(owner, hatID);
    }

     
    function getInterestPayableOf(Account storage account) internal view returns (uint256) {
        uint256 rGross =
            account.sInternalAmount
            .mul(ias.exchangeRateStored())
            .div(savingAssetConversionRate);  
        if (rGross > (account.lDebt + account.rInterest)) {
            return rGross - account.lDebt - account.rInterest;
        } else {
             
            return 0;
        }
    }

     
    function distributeLoans(
            address owner,
            uint256 rAmount,
            uint256 sInternalAmount) internal {
        Account storage account = accounts[owner];
        Hat storage hat = hats[account.hatID == SELF_HAT_ID ? 0 : account.hatID];
        bool[] memory recipientsNeedsNewHat = new bool[](hat.recipients.length);
        uint i;
        if (hat.recipients.length > 0) {
            uint256 rLeft = rAmount;
            uint256 sInternalLeft = sInternalAmount;
            for (i = 0; i < hat.proportions.length; ++i) {
                Account storage recipient = accounts[hat.recipients[i]];
                bool isLastRecipient = i == (hat.proportions.length - 1);

                 
                if (recipient.hatID == 0) {
                    recipientsNeedsNewHat[i] = true;
                }

                uint256 lDebtRecipient = isLastRecipient ? rLeft :
                    rAmount
                    * hat.proportions[i]
                    / PROPORTION_BASE;
                account.lRecipients[hat.recipients[i]] = account.lRecipients[hat.recipients[i]].add(lDebtRecipient);
                recipient.lDebt = recipient.lDebt.add(lDebtRecipient);
                 
                if (rLeft > lDebtRecipient) {
                    rLeft -= lDebtRecipient;
                } else {
                    rLeft = 0;
                }

                uint256 sInternalAmountRecipient = isLastRecipient ? sInternalLeft:
                    sInternalAmount
                    * hat.proportions[i]
                    / PROPORTION_BASE;
                recipient.sInternalAmount = recipient.sInternalAmount.add(sInternalAmountRecipient);
                 
                if (sInternalLeft >= sInternalAmountRecipient) {
                    sInternalLeft -= sInternalAmountRecipient;
                } else {
                    rLeft = 0;
                }
            }
        } else {
             
            account.lDebt = account.lDebt.add(rAmount);
            account.sInternalAmount = account.sInternalAmount.add(sInternalAmount);
        }

         
        for (i = 0; i < hat.proportions.length; ++i) {
            if (recipientsNeedsNewHat[i]) {
                changeHatInternal(hat.recipients[i], account.hatID);
            }
        }
    }

     
    function estimateAndRecollectLoans(
        address owner,
        uint256 rAmount) internal returns (uint256 sInternalAmount) {
        Account storage account = accounts[owner];
        Hat storage hat = hats[account.hatID == SELF_HAT_ID ? 0 : account.hatID];
         
        ias.accrueInterest();
        sInternalAmount = rAmount
            .mul(savingAssetConversionRate)
            .div(ias.exchangeRateStored());  
        recollectLoans(account, hat, rAmount, sInternalAmount);
    }

     
    function redeemAndRecollectLoans(
        address owner,
        uint256 rAmount) internal returns (uint256 sOriginalBurned) {
        Account storage account = accounts[owner];
        Hat storage hat = hats[account.hatID == SELF_HAT_ID ? 0 : account.hatID];
        sOriginalBurned = ias.redeemUnderlying(rAmount);
        uint256 sInternalBurned =
            sOriginalBurned
            .mul(savingAssetConversionRate)
            .div(10 ** 18);
        recollectLoans(account, hat, rAmount, sInternalBurned);
    }

     
    function recollectLoans(
        Account storage account,
        Hat storage hat,
        uint256 rAmount,
        uint256 sInternalAmount) internal {
        uint i;
        if (hat.recipients.length > 0) {
            uint256 rLeft = rAmount;
            uint256 sInternalLeft = sInternalAmount;
            for (i = 0; i < hat.proportions.length; ++i) {
                Account storage recipient = accounts[hat.recipients[i]];
                bool isLastRecipient = i == (hat.proportions.length - 1);

                uint256 lDebtRecipient = isLastRecipient ? rLeft: rAmount
                    * hat.proportions[i]
                    / PROPORTION_BASE;
                if (recipient.lDebt > lDebtRecipient) {
                    recipient.lDebt -= lDebtRecipient;
                } else {
                    recipient.lDebt = 0;
                }
                if (account.lRecipients[hat.recipients[i]] > lDebtRecipient) {
                    account.lRecipients[hat.recipients[i]] -= lDebtRecipient;
                } else {
                    account.lRecipients[hat.recipients[i]] = 0;
                }
                 
                if (rLeft > lDebtRecipient) {
                    rLeft -= lDebtRecipient;
                } else {
                    rLeft = 0;
                }

                uint256 sInternalAmountRecipient = isLastRecipient ? sInternalLeft:
                    sInternalAmount
                    * hat.proportions[i]
                    / PROPORTION_BASE;
                if (recipient.sInternalAmount > sInternalAmountRecipient) {
                    recipient.sInternalAmount -= sInternalAmountRecipient;
                } else {
                    recipient.sInternalAmount = 0;
                }
                 
                if (sInternalLeft >= sInternalAmountRecipient) {
                    sInternalLeft -= sInternalAmountRecipient;
                } else {
                    rLeft = 0;
                }
            }
        } else {
             
            if (account.lDebt > rAmount) {
                account.lDebt -= rAmount;
            } else {
                account.lDebt = 0;
            }
            if (account.sInternalAmount > sInternalAmount) {
                account.sInternalAmount -= sInternalAmount;
            } else {
                account.sInternalAmount = 0;
            }
        }
    }
}
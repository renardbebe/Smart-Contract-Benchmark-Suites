 

pragma solidity ^0.4.18;

 
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


 
contract ERC20Basic {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
}







 
library SafeMath {

     
    function mul(uint256 a, uint256 b) internal pure returns (uint256 c) {
        if (a == 0) {
            return 0;
        }
        c = a * b;
        assert(c / a == b);
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

 
contract ToorToken is ERC20Basic, Ownable {
    using SafeMath for uint256;

    struct Account {
        uint balance;
        uint lastInterval;
    }

    mapping(address => Account) public accounts;
    mapping(uint256 => uint256) ratesByYear;
    mapping (address => mapping (address => uint256)) internal allowed;
    uint256 private rateMultiplier;

    uint256 initialSupply_;
    uint256 totalSupply_;
    uint256 public maxSupply;
    uint256 public startTime;
    uint256 public pendingRewardsToMint;

    string public name;
    uint public decimals;
    string public symbol;

    uint256 private tokenGenInterval;  
    uint256 private vestingPeriod;  
    uint256 private cliff;  
    uint256 public pendingInstallments;  
    uint256 public paidInstallments;  
    uint256 private totalVestingPool;  
    uint256 public pendingVestingPool;  
    uint256 public finalIntervalForTokenGen;  
    uint256 private totalRateWindows;  
    uint256 private intervalsPerWindow;  

     
    bool public rewardGenerationComplete;

     
    mapping(uint256 => address) public distributionAddresses;

     
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed burner, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    function ToorToken() public {
        name = "ToorCoin";
        decimals = 18;
        symbol = "TOOR";

         
        rateMultiplier = 10**9;
        ratesByYear[1] = 1.00474436 * 10**9;
        ratesByYear[2] = 1.003278088 * 10**9;
        ratesByYear[3] = 1.002799842 * 10**9;
        ratesByYear[4] = 1.002443535 * 10**9;
        ratesByYear[5] = 1.002167763 * 10**9;
        ratesByYear[6] = 1.001947972 * 10**9;
        ratesByYear[7] = 1.001768676 * 10**9;
        ratesByYear[8] = 1.001619621 * 10**9;
        ratesByYear[9] = 1.001493749 * 10**9;
        ratesByYear[10] = 1.001386038 * 10**9;
        ratesByYear[11] = 1.001292822 * 10**9;
        ratesByYear[12] = 1.001211358 * 10**9;
        ratesByYear[13] = 1.001139554 * 10**9;
        ratesByYear[14] = 1.001075789 * 10**9;
        ratesByYear[15] = 1.001018783 * 10**9;
        ratesByYear[16] = 1.000967516 * 10**9;
        ratesByYear[17] = 1.000921162 * 10**9;
        ratesByYear[18] = 1.000879048 * 10**9;
        ratesByYear[19] = 1.000840616 * 10**9;
        ratesByYear[20] = 1.000805405 * 10**9;

        totalRateWindows = 20;
        
        maxSupply = 100000000 * 10**18;
        initialSupply_ = 13500000 * 10**18;
        pendingInstallments = 7;
        paidInstallments = 0;
        totalVestingPool = 4500000 * 10**18;
        startTime = now;

        distributionAddresses[1] = 0x7d3BC9bb69dAB0544d34b7302DED8806bCF715e6;  
        distributionAddresses[2] = 0x34Cf9afae3f926B9D040CA7A279C411355c5C480;  
        distributionAddresses[3] = 0x059Cbd8A57b1dD944Da020a0D0a18D8dD7e78E04;  
        distributionAddresses[4] = 0x4F8bC705827Fb8A781b27B9F02d2491F531f8962;  
        distributionAddresses[5] = 0x532d370a98a478714625E9148D1205be061Df3bf;  
        distributionAddresses[6] = 0xDe485bB000fA57e73197eF709960Fb7e32e0380E;  
        distributionAddresses[7] = 0xd562f635c75D2d7f3BE0005FBd3808a5cfb896bd;  
        
         
        tokenGenInterval = 603936;   
        uint256 timeToGenAllTokens = 628093440;  

        rewardGenerationComplete = false;
        
         
        accounts[distributionAddresses[6]].balance = (initialSupply_ * 60) / 100;  
        accounts[distributionAddresses[6]].lastInterval = 0;
        generateMintEvents(distributionAddresses[6],accounts[distributionAddresses[6]].balance);
        accounts[distributionAddresses[7]].balance = (initialSupply_ * 40) / 100;  
        accounts[distributionAddresses[7]].lastInterval = 0;
        generateMintEvents(distributionAddresses[7],accounts[distributionAddresses[7]].balance);

        pendingVestingPool = totalVestingPool;
        pendingRewardsToMint = maxSupply - initialSupply_ - totalVestingPool;
        totalSupply_ = initialSupply_;
        vestingPeriod = timeToGenAllTokens / (totalRateWindows * 12);  
        cliff = vestingPeriod * 6;  
        finalIntervalForTokenGen = timeToGenAllTokens / tokenGenInterval;
        intervalsPerWindow = finalIntervalForTokenGen / totalRateWindows;
    }

     
    function totalSupply() public view returns (uint256) {
        return totalSupply_;
    }

     
    function transfer(address _to, uint256 _value) canTransfer(_to) public returns (bool) {
         
        transferBasic(msg.sender, _to, _value);
        return true;
    }

     
    function transferBasic(address _from, address _to, uint256 _value) internal {
        uint256 tokensOwedSender = 0;
        uint256 tokensOwedReceiver = 0;
        uint256 balSender = balanceOfBasic(_from);

         
        if (!rewardGenerationComplete) {
            tokensOwedSender = tokensOwed(_from);
            require(_value <= (balSender.add(tokensOwedSender)));  

            tokensOwedReceiver = tokensOwed(_to);

             
            if ((tokensOwedSender.add(tokensOwedReceiver)) > 0) {
                increaseTotalSupply(tokensOwedSender.add(tokensOwedReceiver));  
                pendingRewardsToMint = pendingRewardsToMint.sub(tokensOwedSender.add(tokensOwedReceiver));
            }

             
            raiseEventIfMinted(_from, tokensOwedSender);
            raiseEventIfMinted(_to, tokensOwedReceiver);
        } else {
            require(_value <= balSender);
        }
        
         
        accounts[_from].balance = (balSender.add(tokensOwedSender)).sub(_value);
        accounts[_to].balance = (accounts[_to].balance.add(tokensOwedReceiver)).add(_value);

         
        uint256 currInt = intervalAtTime(now);
        accounts[_from].lastInterval = currInt;
        accounts[_to].lastInterval = currInt;

        emit Transfer(_from, _to, _value);
    }

     
    function batchTransfer(address[] _receivers, uint256 _value) public returns (bool) {
        uint256 cnt = _receivers.length;
        uint256 amount = cnt.mul(_value);
        
         
        require(_value > 0);

         
        if (!rewardGenerationComplete) {
            addReward(msg.sender);
        }

         
        uint256 balSender = balanceOfBasic(msg.sender);

         
        require(balSender >= amount);

         
        accounts[msg.sender].balance = balSender.sub(amount);
        uint256 currInt = intervalAtTime(now);
        accounts[msg.sender].lastInterval = currInt;
        
        
        for (uint i = 0; i < cnt; i++) {
             
            if (!rewardGenerationComplete) {
                address receiver = _receivers[i];
                
                addReward(receiver);
            }

             
            accounts[_receivers[i]].balance = (accounts[_receivers[i]].balance).add(_value);
            accounts[_receivers[i]].lastInterval = currInt;
            emit Transfer(msg.sender, _receivers[i], _value);
        }

        return true;
    }

     
     
    function transferFrom(address _from, address _to, uint256 _value) canTransfer(_to) public returns (bool)
    {
         
        require(_value <= allowed[_from][msg.sender]);

         
        transferBasic(_from, _to, _value);

         
        allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);

        return true;
    }

   
    function approve(address _spender, uint256 _value) public returns (bool) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

       
    function allowance(address _owner, address _spender) public view returns (uint256)
    {
        return allowed[_owner][_spender];
    }

  
    
    
    
    function increaseApproval(address _spender, uint _addedValue) public returns (bool)
    {
        allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    
    
    
    function decreaseApproval(address _spender, uint _subtractedValue) public returns (bool)
    {
        uint oldValue = allowed[msg.sender][_spender];
        if (_subtractedValue > oldValue) {
            allowed[msg.sender][_spender] = 0;
        } else {
            allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
        }
        emit Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
        return true;
    }

    function raiseEventIfMinted(address owner, uint256 tokensToReward) private returns (bool) {
        if (tokensToReward > 0) {
            generateMintEvents(owner, tokensToReward);
        }
    }

    function addReward(address owner) private returns (bool) {
        uint256 tokensToReward = tokensOwed(owner);

        if (tokensToReward > 0) {
            increaseTotalSupply(tokensToReward);  
            accounts[owner].balance = accounts[owner].balance.add(tokensToReward);
            accounts[owner].lastInterval = intervalAtTime(now);
            pendingRewardsToMint = pendingRewardsToMint.sub(tokensToReward);  
            generateMintEvents(owner, tokensToReward);
        }

        return true;
    }

     
     
    function vestTokens() public returns (bool) {
        require(pendingInstallments > 0);
        require(paidInstallments < 7);
        require(pendingVestingPool > 0);
        require(now - startTime > cliff);

         
        if (!rewardGenerationComplete) {
            for (uint256 i = 1; i <= 5; i++) {
                addReward(distributionAddresses[i]);
            }
        }

        uint256 currInterval = intervalAtTime(now);
        uint256 tokensToVest = 0;
        uint256 totalTokensToVest = 0;
        uint256 totalPool = totalVestingPool;

        uint256[2] memory founderCat;
        founderCat[0] = 0;
        founderCat[1] = 0;

        uint256[5] memory origFounderBal;
        origFounderBal[0] = accounts[distributionAddresses[1]].balance;
        origFounderBal[1] = accounts[distributionAddresses[2]].balance;
        origFounderBal[2] = accounts[distributionAddresses[3]].balance;
        origFounderBal[3] = accounts[distributionAddresses[4]].balance;
        origFounderBal[4] = accounts[distributionAddresses[5]].balance;

        uint256[2] memory rewardCat;
        rewardCat[0] = 0;
        rewardCat[1] = 0;

         
        if (paidInstallments < 1) {
            uint256 intervalAtCliff = intervalAtTime(cliff + startTime);
            tokensToVest = totalPool / 4;

            founderCat[0] = tokensToVest / 4;
            founderCat[1] = tokensToVest / 8;

             
            pendingVestingPool -= tokensToVest;

             
            if (currInterval > intervalAtCliff && !rewardGenerationComplete) {
                rewardCat[0] = tokensOwedByInterval(founderCat[0], intervalAtCliff, currInterval);
                rewardCat[1] = rewardCat[0] / 2;

                 
                founderCat[0] += rewardCat[0];
                founderCat[1] += rewardCat[1];

                 
                tokensToVest += ((3 * rewardCat[0]) + (2 * rewardCat[1]));

                 
                pendingRewardsToMint -= ((3 * rewardCat[0]) + (2 * rewardCat[1]));
            }

             
            accounts[distributionAddresses[1]].balance += founderCat[0];
            accounts[distributionAddresses[2]].balance += founderCat[0];
            accounts[distributionAddresses[3]].balance += founderCat[0];
            accounts[distributionAddresses[4]].balance += founderCat[1];
            accounts[distributionAddresses[5]].balance += founderCat[1];

            totalTokensToVest = tokensToVest;

             
            pendingInstallments -= 1;
            paidInstallments += 1;
        }

         
        uint256 installments = ((currInterval * tokenGenInterval) - cliff) / vestingPeriod;
        uint256 installmentsToPay = installments + 1 - paidInstallments;

         
        if (installmentsToPay > 0) {
            if (installmentsToPay > pendingInstallments) {
                installmentsToPay = pendingInstallments;
            }

             
            tokensToVest = (totalPool * 125) / 1000;

            founderCat[0] = tokensToVest / 4;
            founderCat[1] = tokensToVest / 8;

            uint256 intervalsAtVest = 0;

             
            for (uint256 installment = paidInstallments; installment < (installmentsToPay + paidInstallments); installment++) {
                intervalsAtVest = intervalAtTime(cliff + (installment * vestingPeriod) + startTime);

                 
                if (currInterval >= intervalsAtVest && !rewardGenerationComplete) {
                    rewardCat[0] = tokensOwedByInterval(founderCat[0], intervalsAtVest, currInterval);
                    rewardCat[1] = rewardCat[0] / 2;

                     
                    totalTokensToVest += tokensToVest;
                    totalTokensToVest += ((3 * rewardCat[0]) + (2 * rewardCat[1]));

                     
                    pendingRewardsToMint -= ((3 * rewardCat[0]) + (2 * rewardCat[1]));

                     
                    accounts[distributionAddresses[1]].balance += (founderCat[0] + rewardCat[0]);
                    accounts[distributionAddresses[2]].balance += (founderCat[0] + rewardCat[0]);
                    accounts[distributionAddresses[3]].balance += (founderCat[0] + rewardCat[0]);
                    accounts[distributionAddresses[4]].balance += (founderCat[1] + rewardCat[1]);
                    accounts[distributionAddresses[5]].balance += (founderCat[1] + rewardCat[1]);
                }
            }

             
            pendingVestingPool -= (installmentsToPay * tokensToVest);
            pendingInstallments -= installmentsToPay;
            paidInstallments += installmentsToPay;
        }

         
        increaseTotalSupply(totalTokensToVest);
            
        accounts[distributionAddresses[1]].lastInterval = currInterval;
        accounts[distributionAddresses[2]].lastInterval = currInterval;
        accounts[distributionAddresses[3]].lastInterval = currInterval;
        accounts[distributionAddresses[4]].lastInterval = currInterval;
        accounts[distributionAddresses[5]].lastInterval = currInterval;

         
        generateMintEvents(distributionAddresses[1], (accounts[distributionAddresses[1]].balance - origFounderBal[0]));
        generateMintEvents(distributionAddresses[2], (accounts[distributionAddresses[2]].balance - origFounderBal[1]));
        generateMintEvents(distributionAddresses[3], (accounts[distributionAddresses[3]].balance - origFounderBal[2]));
        generateMintEvents(distributionAddresses[4], (accounts[distributionAddresses[4]].balance - origFounderBal[3]));
        generateMintEvents(distributionAddresses[5], (accounts[distributionAddresses[5]].balance - origFounderBal[4]));
    }

    function increaseTotalSupply (uint256 tokens) private returns (bool) {
        require ((totalSupply_.add(tokens)) <= maxSupply);
        totalSupply_ = totalSupply_.add(tokens);

        return true;
    }

    function tokensOwed(address owner) public view returns (uint256) {
         
        uint256 currInterval = intervalAtTime(now);
        uint256 lastInterval = accounts[owner].lastInterval;
        uint256 balance = accounts[owner].balance;

        return tokensOwedByInterval(balance, lastInterval, currInterval);
    }

    function tokensOwedByInterval(uint256 balance, uint256 lastInterval, uint256 currInterval) public view returns (uint256) {
         
        if (lastInterval >= currInterval || lastInterval >= finalIntervalForTokenGen) {
            return 0;
        }

        uint256 tokensHeld = balance;  
        uint256 intPerWin = intervalsPerWindow;
        uint256 totalRateWinds = totalRateWindows;

         
        uint256 intPerBatch = 5;  

        mapping(uint256 => uint256) ratByYear = ratesByYear;
        uint256 ratMultiplier = rateMultiplier;

        uint256 minRateWindow = (lastInterval / intPerWin).add(1);
        uint256 maxRateWindow = (currInterval / intPerWin).add(1);
        if (maxRateWindow > totalRateWinds) {
            maxRateWindow = totalRateWinds;
        }

         
        for (uint256 rateWindow = minRateWindow; rateWindow <= maxRateWindow; rateWindow++) {
            uint256 intervals = getIntervalsForWindow(rateWindow, lastInterval, currInterval, intPerWin);

             
             
            while (intervals > 0) {
                if (intervals >= intPerBatch) {
                    tokensHeld = (tokensHeld.mul(ratByYear[rateWindow] ** intPerBatch)) / (ratMultiplier ** intPerBatch);
                    intervals = intervals.sub(intPerBatch);
                } else {
                    tokensHeld = (tokensHeld.mul(ratByYear[rateWindow] ** intervals)) / (ratMultiplier ** intervals);
                    intervals = 0;
                }
            }            
        }

         
        return (tokensHeld.sub(balance));
    }

    function intervalAtTime(uint256 time) public view returns (uint256) {
         
        if (time <= startTime) {
            return 0;
        }

         
        uint256 interval = (time.sub(startTime)) / tokenGenInterval;
        uint256 finalInt = finalIntervalForTokenGen;  
        
         
        if (interval > finalInt) {
            return finalInt;
        } else {
            return interval;
        }
    }

     
    function getIntervalsForWindow(uint256 rateWindow, uint256 lastInterval, uint256 currInterval, uint256 intPerWind) public pure returns (uint256) {
         
        if (lastInterval < ((rateWindow.sub(1)).mul(intPerWind))) {
            lastInterval = ((rateWindow.sub(1)).mul(intPerWind));
        }

         
        if (currInterval > rateWindow.mul(intPerWind)) {
            currInterval = rateWindow.mul(intPerWind);
        }

        return currInterval.sub(lastInterval);
    }

     
    function balanceOf(address _owner) public view returns (uint256 balance) {
        if (rewardGenerationComplete) {
            return accounts[_owner].balance;
        } else {
            return (accounts[_owner].balance).add(tokensOwed(_owner));
        }
    }

    function balanceOfBasic(address _owner) public view returns (uint256 balance) {
        return accounts[_owner].balance;
    }

     
    function lastTimeOf(address _owner) public view returns (uint256 interval, uint256 time) {
        return (accounts[_owner].lastInterval, ((accounts[_owner].lastInterval).mul(tokenGenInterval)).add(startTime));
    }

     
    function mint(address _to, uint256 _amount) onlyOwner public returns (bool) {
         
        if (!rewardGenerationComplete) {
            addReward(_to);
        }

         
        increaseTotalSupply(_amount);

         
        accounts[_to].lastInterval = intervalAtTime(now);
        accounts[_to].balance = (accounts[_to].balance).add(_amount);

        generateMintEvents(_to, _amount);
        return true;
    }

    function generateMintEvents(address _to, uint256 _amount) private returns (bool) {
        emit Mint(_to, _amount);
        emit Transfer(address(0), _to, _amount);

        return true;
    }

     
    function burn(uint256 _value) public {
        require(_value <= balanceOf(msg.sender));

         
        if (!rewardGenerationComplete) {
            addReward(msg.sender);
        }

         
        accounts[msg.sender].balance = (accounts[msg.sender].balance).sub(_value);
        accounts[msg.sender].lastInterval = intervalAtTime(now);

         
        totalSupply_ = totalSupply_.sub(_value);

         
        emit Burn(msg.sender, _value);
        emit Transfer(msg.sender, address(0), _value);
    }

     
    function setFounder(uint256 id, address _to) onlyOwner public returns (bool) {
        require(_to != address(0));
        distributionAddresses[id] = _to;
        return true;
    }

     
    function setRewardGenerationComplete(bool _value) onlyOwner public returns (bool) {
        rewardGenerationComplete = _value;
        return true;
    }

     
    function getNow() public view returns (uint256, uint256, uint256) {
        return (now, block.number, intervalAtTime(now));
    }

     
    modifier canTransfer(address _to) {
        require(_to != address(0));  
        _;
    }
}
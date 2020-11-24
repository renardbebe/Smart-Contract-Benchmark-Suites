 

contract EtherAds {
     
    event BuyAd(address etherAddress, uint amount, string href, string anchor, string imgId, uint headerColor, uint8 countryId, address referral);
    event ResetContract();
    event PayoutEarnings(address etherAddress, uint amount, uint8 referralLevel);
    struct Ad {
        address etherAddress;
        uint amount;
        string href;
        string anchor;
        string imgId;
        uint8 countryId;
        int refId;
    }
    struct charityFundation {
        string href;
        string anchor;
        string imgId;
    }
    charityFundation[] public charityFundations;
    uint public charityFoundationIdx = 0;
    string public officialWebsite;
    Ad[] public ads;
    uint public payoutIdx = 0;
    uint public balance = 0;
    uint public fees = 0;
    uint public contractExpirationTime;
    uint public headerColor = 0x000000;
    uint public maximumDeposit = 42 ether;
     
    uint[7] public txsThreshold = [10, 20, 50, 100, 200, 500, 1000];
     
    uint[8] public prolongH = [
        336 hours, 168 hours, 67 hours, 33 hours,
        16 hours, 6 hours, 3 hours, 1 hours
    ];
     
    uint[8] public minDeposits = [
        100 szabo, 400 szabo, 2500 szabo, 10 finney,
        40 finney, 250 finney, 1 ether, 5 ether
    ];
     
    uint[24] public txsPerHour;
    uint public lastHour;  
    uint public frozenMinDeposit = 0;
     
    address[3] owners;
     
    modifier onlyowners {
        if (msg.sender == owners[0] || msg.sender == owners[1] || msg.sender == owners[2]) _
    }
     
    function EtherAds(address owner0, address owner1, address owner2) {
        owners[0] = owner0;
        owners[1] = owner1;
        owners[2] = owner2;
    }
     
     
     
     
     
     
     
     
    function() {
        buyAd(
            charityFundations[charityFoundationIdx].href,
            charityFundations[charityFoundationIdx].anchor,
            charityFundations[charityFoundationIdx].imgId,
            0xff8000,
            0,  
            msg.sender
        );
        charityFoundationIdx += 1;
        if (charityFoundationIdx >= charityFundations.length) {
            charityFoundationIdx = 0;
        }
    }
     
    function buyAd(string href, string anchor, string imgId, uint _headerColor, uint8 countryId, address referral) {
        uint value = msg.value;
        uint minimalDeposit = getMinimalDeposit();
         
        if (value < minimalDeposit) throw;
         
        if (value > maximumDeposit) {
            msg.sender.send(value - maximumDeposit);
            value = maximumDeposit;
        }
         
        if (bytes(href).length > 100 || bytes(anchor).length > 50) throw;
         
        resetContract();
         
        uint id = ads.length;
         
        ads.length += 1;
        ads[id].etherAddress = msg.sender;
        ads[id].amount = value;
        ads[id].href = href;
        ads[id].imgId = imgId;
        ads[id].anchor = anchor;
        ads[id].countryId = countryId;
         
        balance += value;
         
        headerColor = _headerColor;
         
        BuyAd(msg.sender, value, href, anchor, imgId, _headerColor, countryId, referral);
        updateTxStats();
         
        setReferralId(id, referral);
        distributeEarnings();
    }
    function prolongateContract() private {
        uint level = getCurrentLevel();
        contractExpirationTime = now + prolongH[level];
    }
    function getMinimalDeposit() returns (uint) {
        uint txsThresholdIndex = getCurrentLevel();
        if (minDeposits[txsThresholdIndex] > frozenMinDeposit) {
            frozenMinDeposit = minDeposits[txsThresholdIndex];
        }
        return frozenMinDeposit;
    }
    function getCurrentLevel() returns (uint) {
        uint txsPerLast24hours = 0;
        uint i = 0;
        while (i < 24) {
            txsPerLast24hours += txsPerHour[i];
            i += 1;
        }
        i = 0;
        while (txsPerLast24hours > txsThreshold[i]) {
            i = i + 1;
        }
        return i;
    }
    function updateTxStats() private {
        uint currtHour = now / (60 * 60);
        uint txsCounter = txsPerHour[currtHour];
        if (lastHour < currtHour) {
            txsCounter = 0;
            lastHour = currtHour;
        }
        txsCounter += 1;
        txsPerHour[currtHour] = txsCounter;
    }
     
    function distributeEarnings() private {
         
        while (true) {
             
            uint amount = ads[payoutIdx].amount * 2;
             
            if (balance >= amount) {
                 
                ads[payoutIdx].etherAddress.send(amount / 100 * 80);
                PayoutEarnings(ads[payoutIdx].etherAddress, amount / 100 * 80, 0);
                 
                fees += amount / 100 * 15;
                 
                uint level0Fee = amount / 1000 * 25;  
                uint level1Fee = amount / 1000 * 15;  
                uint level2Fee = amount / 1000 * 10;  
                 
                int refId = ads[payoutIdx].refId;
                if (refId == -1) {
                     
                    balance += level0Fee + level1Fee + level2Fee;
                } else {
                    ads[uint(refId)].etherAddress.send(level0Fee);
                    PayoutEarnings(ads[uint(refId)].etherAddress, level0Fee, 1);
                    
                    refId = ads[uint(refId)].refId;
                    if (refId == -1) {
                         
                        balance += level1Fee + level2Fee;
                    } else {
                         
                        ads[uint(refId)].etherAddress.send(level1Fee);
                        PayoutEarnings(ads[uint(refId)].etherAddress, level1Fee, 2);
                     
                        refId = ads[uint(refId)].refId;
                        if (refId == -1) {
                             
                            balance += level2Fee;
                        } else {
                             
                            ads[uint(refId)].etherAddress.send(level2Fee);
                            PayoutEarnings(ads[uint(refId)].etherAddress, level2Fee, 3);
                        }
                    }
                }
                balance -= amount;
                payoutIdx += 1;
            } else {
                 
                 
                break;
            }
        }
    }
     
     
    function resetContract() private {
         
        if (now > contractExpirationTime) {
             
            balance = balance / 2;
            ads[ads.length-1].etherAddress.send(balance);
             
            ads.length = 0;
             
            payoutIdx = 0;
            contractExpirationTime = now + 14 days;
            frozenMinDeposit = 0;
             
            uint i = 0;
            while (i < 24) {
                txsPerHour[i] = 0;
                i += 1;
            }
             
            ResetContract();
        }
    }
     
    function setReferralId(uint id, address referral) private {
        uint i = 0;
         
         
        int refId = -1;
         
        while (i < ads.length) {
             
            if (ads[i].etherAddress == referral) {
                refId = int(i);
                break;
            }
            i += 1;
        }
         
        ads[id].refId = refId;
    }

     
    function collectFees() onlyowners {
        if (fees == 0) return;  
        uint sharedFee = fees / 3;
        uint i = 0;
        while (i < 3) {
            owners[i].send(sharedFee);
            i += 1;
        }
         
        fees = 0;
    }
     
    function changeOwner(address newOwner) onlyowners {
        uint i = 0;
        while (i < 3) {
             
            if (msg.sender == owners[i]) {
                 
                owners[i] = newOwner;
            }
            i += 1;
        }
    }
     
    function setOfficialWebsite(string url) onlyowners {
        officialWebsite = url;
    }
     
    function addCharityFundation(string href, string anchor, string imgId) onlyowners {
        uint id = charityFundations.length;
         
        charityFundations.length += 1;
        charityFundations[id].href = href;
        charityFundations[id].anchor = anchor;
        charityFundations[id].imgId = imgId;
    }
     
    function resetFoundationtList() onlyowners {
        charityFundations.length = 0;
    }
    function giveMeat() onlyowners {
         
        balance += msg.value;
    }
}
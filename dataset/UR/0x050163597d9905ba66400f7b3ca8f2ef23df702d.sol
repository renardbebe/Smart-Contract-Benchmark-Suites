 

pragma solidity ^0.4.19;

interface ERC20 {
  function totalSupply() public view returns (uint256);
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);

  event Approval(address indexed owner, address indexed spender, uint256 value);
  event Transfer(address indexed from, address indexed to, uint256 value);
}

 
contract Owned {
   
  address owner;

   
  function Owned() public {
    owner = msg.sender;
  }

   
  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }
}

 
contract ChiSale is Owned {
     
     
     
     
     
    struct BonusTier {
        uint256 percentage;
        uint256 threshold;
    }

     
     
    BonusTier[] private bonusTiers;

     
     
    uint256 private tokensSold;

     
     
    uint8 private bonusIndex;

     
     
     
    uint256 private maxBonusThreshold;

     
     
     
    uint256 private constant TOKEN_PRICE = 0.001 ether;

     
     
     
     
    uint256 private constant REVENUE_SHARE_PERCENTAGE = 22;

     
    ERC20 private chiContract;

     
     
    event LogChiPurchase(
        address indexed buyer,
        address indexed referrer,
        uint256 number,
        uint256 timestamp
    );

     
    function ChiSale(
        address chiAddress,
        uint256[] bonusThresholds,
        uint256[] bonusPercentages
    )
        public
        Owned()
    {
         
         
         
        require(bonusThresholds.length == bonusPercentages.length);

         
         
         
        require(bonusThresholds.length < 256);

         
         
         
        for (uint8 i = 0; i < bonusThresholds.length; i++) {

             
             
            if (i > 0) {
                require(bonusThresholds[i] > bonusThresholds[i - 1]);
            }

             
             
             
            if (i > bonusThresholds.length - 1) {
                maxBonusThreshold = bonusThresholds[i];
            }

            bonusTiers.push(BonusTier({
                percentage: bonusPercentages[i],
                threshold: bonusThresholds[i]
            }));
        }

         
         
        chiContract = ERC20(chiAddress);

         
         
         
        tokensSold = 0;
        bonusIndex = 0;
    }

    function buy(address referralAddress) external payable {
         
         
         
        uint256 tokensToBuy = msg.value / TOKEN_PRICE;

         
         
        uint256 tokenBalance = chiContract.balanceOf(address(this));

         
         
         
        uint256 remainder = msg.value % TOKEN_PRICE;

         
         
         
         
        if (maxBonusThreshold < tokenBalance) {
            maxBonusThreshold = tokenBalance;
        }

         
         
         
        if (tokensToBuy > maxBonusThreshold) {
            tokensToBuy = maxBonusThreshold;

             
             
             
             
             
            remainder = msg.value - tokensToBuy * TOKEN_PRICE;
        }

         
         
         
        uint256 bonusTokens = calculateBonusTokens(tokensToBuy);

         
         
         
        tokensSold += tokensToBuy;

         
         
         
         
         
        if (tokenBalance < tokensToBuy + bonusTokens) {
            chiContract.transfer(msg.sender, tokenBalance);
        } else {
            chiContract.transfer(msg.sender, tokensToBuy + bonusTokens);
        }

         
         
         
         
         
        if (referralAddress != address(this) && referralAddress != address(0)) {

             
             
             
             
             
             
             
            referralAddress.send(
                msg.value * REVENUE_SHARE_PERCENTAGE / 100
            );
        }

         
         
         
        if (remainder > 0) {
            msg.sender.transfer(remainder);
        }

        LogChiPurchase(msg.sender, referralAddress, tokensToBuy, now);
    }

     
    function resetMaxBonusThreshold() external onlyOwner {
        maxBonusThreshold = bonusTiers[bonusTiers.length - 1].threshold;
    }

     
    function withdrawEther() external onlyOwner {
         
         
        msg.sender.transfer(address(this).balance);
    }

     
    function withdrawChi() external onlyOwner {
         
         
         
         
        chiContract.transfer(msg.sender, chiContract.balanceOf(address(this)));
    }

     
    function getBonusTierCount() external view returns (uint256) {
        return bonusTiers.length;
    }

     
    function getBonusTier(
        uint8 bonusTierIndex
    )
        external
        view
        returns (uint256, uint256)
    {
        return (
            bonusTiers[bonusTierIndex].percentage,
            bonusTiers[bonusTierIndex].threshold
        );
    }

     
    function getCurrentBonusTier()
        external
        view
        returns (uint256 percentage, uint256 threshold)
    {
        return (
            bonusTiers[bonusIndex].percentage,
            bonusTiers[bonusIndex].threshold
        );
    }

     
    function getNextBonusIndex()
        external
        view
        returns (uint8)
    {
        return bonusIndex + 1;
    }

     
    function getSoldTokens() external view returns (uint256) {
        return tokensSold;
    }

     
    function calculateBonusTokens(
        uint256 boughtTokens
    )
        internal
        returns (uint256)
    {
         
        if (bonusIndex == bonusTiers.length) {
            return 0;
        }

         
         
         
         
        uint256 bonusTokens = 0;

         
        uint256 _boughtTokens = boughtTokens;

         
        uint256 _tokensSold = tokensSold;

        while (_boughtTokens > 0) {
            uint256 threshold = bonusTiers[bonusIndex].threshold;
            uint256 bonus = bonusTiers[bonusIndex].percentage;

             
             
             
             
             
            if (_tokensSold + _boughtTokens >= threshold) {
                 
                 
                 
                _boughtTokens -= threshold - _tokensSold;

                 
                 
                 
                 
                 
                 
                 
                 
                 
                bonusTokens += (threshold - _tokensSold) * bonus / 100;

                 
                 
                 
                 
                 
                 
                _tokensSold = threshold;

                 
                 
                 
                if (bonusIndex < bonusTiers.length) {
                    bonusIndex += 1;
                }
            } else {

                 
                 
                 
                 
                _tokensSold += _boughtTokens;

                 
                 
                 
                bonusTokens += _boughtTokens * bonus / 100;

                 
                _boughtTokens = 0;
            }
        }

        return bonusTokens;
    }
}
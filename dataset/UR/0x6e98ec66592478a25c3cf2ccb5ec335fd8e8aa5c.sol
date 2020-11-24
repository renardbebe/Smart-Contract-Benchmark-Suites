 

pragma solidity ^0.4.19;

 

 

 
contract SafeMath 
{
    function mul(uint a, uint b) internal pure returns (uint) 
    {
        uint c = a * b;
        assert(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint) 
    {
        assert(b > 0);
        uint c = a / b;
        assert(a == b * c + a % b);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint) 
    {
        assert(b <= a);
        return a - b;
    }

    function add(uint a, uint b) internal pure returns (uint) 
    {
        uint c = a + b;
        assert(c >= a);
        return c;
    }

    function assert(bool assertion) internal pure
    {
        if (!assertion) 
        {
            revert();
        }   
    }
}

contract EtherBonds is SafeMath
{
     
     
    string public README = "STATUS_OK";
    
     
     
     
     
    uint32 AgentBonusInPercent = 10;
     
    uint32 UserRefBonusInPercent = 3;
    
     
    uint32 MinMaturityTimeInDays = 30;  
    uint32 MaxMaturityTimeInDays = 240;
    
     
    uint MinNominalBondPrice = 0.006 ether;
    
     
    uint32 PrematureRedeemPartInPercent = 25;
     
    uint32 PrematureRedeemCostInPercent = 20;
    
     
     
     
    uint32 RedeemRangeInDays = 1;
    uint32 ExtraRedeemRangeInDays = 3;
     
    uint32 ExtraRedeemRangeCostInPercent = 10;
    
     
     
    address public Founder;
    uint32 public FounderFeeInPercent = 5;
    
     
    event Issued(uint32 bondId, address owner);
    event Sold(uint32 bondId, address seller, address buyer, uint price);
    event SellOrderPlaced(uint32 bondId, address seller);
    event SellOrderCanceled(uint32 bondId, address seller);
    event Redeemed(uint32 bondId, address owner);
    
    struct Bond 
    {
         
        uint32 id;
        
        address owner;
        
        uint32 issueTime;
        uint32 maturityTime;
        uint32 redeemTime;
        
         
        uint32 maxRedeemTime;
        bool canBeRedeemedPrematurely;
        
        uint nominalPrice;
        uint maturityPrice;
        
         
        uint sellingPrice;
    }
    uint32 NextBondID = 1;
    mapping(uint32 => Bond) public Bonds;
    
    struct UserInfo
    {
         
        address agent;
        
        uint32 totalBonds;
        mapping(uint32 => uint32) bonds;
    }
    mapping(address => UserInfo) public Users;

    mapping(address => uint) public Balances;

     
    
    function EtherBonds() public 
    {
        Founder = msg.sender;
    }
    
    function ContractInfo() 
        public view returns(
            string readme,
            uint32 agentBonusInPercent,
            uint32 userRefBonusInPercent,
            uint32 minMaturityTimeInDays,
            uint32 maxMaturityTimeInDays,
            uint minNominalBondPrice,
            uint32 prematureRedeemPartInPercent,
            uint32 prematureRedeemCostInPercent,
            uint32 redeemRangeInDays,
            uint32 extraRedeemRangeInDays,
            uint32 extraRedeemRangeCostInPercent,
            uint32 nextBondID,
            uint balance
            )
    {
        readme = README;
        agentBonusInPercent = AgentBonusInPercent;
        userRefBonusInPercent = UserRefBonusInPercent;
        minMaturityTimeInDays = MinMaturityTimeInDays;
        maxMaturityTimeInDays = MaxMaturityTimeInDays;
        minNominalBondPrice = MinNominalBondPrice;
        prematureRedeemPartInPercent = PrematureRedeemPartInPercent;
        prematureRedeemCostInPercent = PrematureRedeemCostInPercent;
        redeemRangeInDays = RedeemRangeInDays;
        extraRedeemRangeInDays = ExtraRedeemRangeInDays;
        extraRedeemRangeCostInPercent = ExtraRedeemRangeCostInPercent;
        nextBondID = NextBondID;
        balance = this.balance;
    }
    
     
    function MaturityPrice(
        uint nominalPrice, 
        uint32 maturityTimeInDays,
        bool hasExtraRedeemRange,
        bool canBeRedeemedPrematurely,
        bool hasRefBonus
        ) 
        public view returns(uint)
    {
        uint nominalPriceModifierInPercent = 100;
        
        if (hasExtraRedeemRange)
        {
            nominalPriceModifierInPercent = sub(
                nominalPriceModifierInPercent, 
                ExtraRedeemRangeCostInPercent
                );
        }
        
        if (canBeRedeemedPrematurely)
        {
            nominalPriceModifierInPercent = sub(
                nominalPriceModifierInPercent, 
                PrematureRedeemCostInPercent
                );
        }
        
        if (hasRefBonus)
        {
            nominalPriceModifierInPercent = add(
                nominalPriceModifierInPercent, 
                UserRefBonusInPercent
                );
        }
        
        nominalPrice = div(
            mul(nominalPrice, nominalPriceModifierInPercent), 
            100
            );
        
         
         
        
        uint x = maturityTimeInDays;
        
         
        require(x >= 15);
        
        var a = mul(2134921000, x);
        var b = mul(mul(111234600, x), x);
        var c = mul(mul(mul(1019400, x), x), x);
        var d = mul(mul(mul(mul(5298, x), x), x), x);
        
        var k = sub(sub(add(add(117168300000, b), d), a), c);
        k = div(k, 10000000);
        
        return div(mul(nominalPrice, k), 10000);
    }
    
     
    function CanBeRedeemed(Bond bond) 
        internal view returns(bool) 
    {
        return 
            bond.issueTime > 0 &&                        
            bond.owner != 0 &&                           
            bond.redeemTime == 0 &&                      
            bond.sellingPrice == 0 &&                    
            (
                !IsPremature(bond.maturityTime) ||       
                bond.canBeRedeemedPrematurely
            ) &&       
            block.timestamp <= bond.maxRedeemTime;       
    }
    
     
    function IsPremature(uint maturityTime)
        public view returns(bool) 
    {
        return maturityTime > block.timestamp;
    }
    
     
    function Buy(
        uint32 maturityTimeInDays,
        bool hasExtraRedeemRange,
        bool canBeRedeemedPrematurely,
        address agent  
        ) 
        public payable
    {
         
        require(msg.value >= MinNominalBondPrice);
        
         
        require(
            maturityTimeInDays >= MinMaturityTimeInDays && 
            maturityTimeInDays <= MaxMaturityTimeInDays
            );
            
         
        bool hasRefBonus = false;
            
         
        if (Users[msg.sender].agent == 0 && Users[msg.sender].totalBonds == 0)
        {
             
            if (agent != 0)
            {
                 
                if (Users[agent].totalBonds > 0)
                {
                    Users[msg.sender].agent = agent;
                    hasRefBonus = true;
                }
                else
                {
                    agent = 0;
                }
            }
        }
         
        else
        {
            agent = Users[msg.sender].agent;
        }
            
         
        Bond memory newBond;
        newBond.id = NextBondID;
        newBond.owner = msg.sender;
        newBond.issueTime = uint32(block.timestamp);
        newBond.canBeRedeemedPrematurely = canBeRedeemedPrematurely;
        
         
        newBond.maturityTime = 
            newBond.issueTime + maturityTimeInDays*24*60*60;
        
             
        newBond.maxRedeemTime = 
            newBond.maturityTime + (hasExtraRedeemRange?ExtraRedeemRangeInDays:RedeemRangeInDays)*24*60*60;
        
        newBond.nominalPrice = msg.value;
        
        newBond.maturityPrice = MaturityPrice(
            newBond.nominalPrice,
            maturityTimeInDays,
            hasExtraRedeemRange,
            canBeRedeemedPrematurely,
            hasRefBonus
            );
        
        Bonds[newBond.id] = newBond;
        NextBondID += 1;
        
         
        var user = Users[newBond.owner];
        user.bonds[user.totalBonds] = newBond.id;
        user.totalBonds += 1;
        
         
        Issued(newBond.id, newBond.owner);
        
         
        uint moneyToFounder = div(
            mul(newBond.nominalPrice, FounderFeeInPercent), 
            100
            );
         
        uint moneyToAgent = div(
            mul(newBond.nominalPrice, AgentBonusInPercent), 
            100
            );
        
        if (agent != 0 && moneyToAgent > 0)
        {
             
            Balances[agent] = add(Balances[agent], moneyToAgent);
        }
        
         
        require(moneyToFounder > 0);
        
        Founder.transfer(moneyToFounder);
    }
    
     
    function BuyOnSecondaryMarket(uint32 bondId) 
        public payable
    {
        var bond = Bonds[bondId];
        
         
        require(bond.issueTime > 0);
         
        require(bond.redeemTime == 0 && block.timestamp < bond.maxRedeemTime);
        
        var price = bond.sellingPrice;
         
        require(price > 0);
         
        require(price <= msg.value);
        
         
        var residue = msg.value - price;
        
         
        var oldOwner = bond.owner;
        var newOwner = msg.sender;
        require(newOwner != 0 && newOwner != oldOwner);
        
        bond.sellingPrice = 0;
        bond.owner = newOwner;
        
        var user = Users[bond.owner];
        user.bonds[user.totalBonds] = bond.id;
        user.totalBonds += 1;
        
         
        require(add(price, residue) == msg.value);
        
         
        Sold(bond.id, oldOwner, newOwner, price);
        
         
        Balances[oldOwner] = add(Balances[oldOwner], price);
        
        if (residue > 0)
        {
             
            newOwner.transfer(residue);
        }
    }
    
     
    function PlaceSellOrder(uint32 bondId, uint sellingPrice) 
        public
    {
         
         
        require(sellingPrice >= MinNominalBondPrice);
        
        var bond = Bonds[bondId];
        
         
        require(bond.issueTime > 0);
         
        require(bond.sellingPrice == 0);
         
        require(bond.redeemTime == 0 && block.timestamp < bond.maxRedeemTime);
         
        require(bond.owner == msg.sender);
        
        bond.sellingPrice = sellingPrice;
        
         
        SellOrderPlaced(bond.id, bond.owner);
    }
    
     
    function CancelSellOrder(uint32 bondId) 
        public
    {
        var bond = Bonds[bondId];
        
         
        require(bond.sellingPrice > 0);
        
         
        require(bond.owner == msg.sender);
        
        bond.sellingPrice = 0;
        
         
        SellOrderCanceled(bond.id, bond.owner);
    }
    
     
    function Withdraw()
        public
    {
        require(Balances[msg.sender] > 0);

         
        var money = Balances[msg.sender];
        Balances[msg.sender] = 0;

        msg.sender.transfer(money);
    }

     
     
     
    function Redeem(uint32 bondId) 
        public
    {
        var bond = Bonds[bondId];
        
        require(CanBeRedeemed(bond));
        
         
        require(bond.owner == msg.sender);
        
         
        bond.redeemTime = uint32(block.timestamp);
        
         
        if (IsPremature(bond.maturityTime))
        {
            bond.maturityPrice = div(
                mul(bond.nominalPrice, PrematureRedeemPartInPercent), 
                100
                );
        }
        
         
        Redeemed(bond.id, bond.owner);
        
         
         
        bond.owner.transfer(bond.maturityPrice);
    }
    
     
    function UserBondByOffset(uint32 offset) 
        public view 
        returns(
            uint32 bondId,
            bool canBeRedeemed,
            bool isPremature
            ) 
    {
        var bond = Bonds[Users[msg.sender].bonds[offset]];
        
        bondId = bond.id;
        canBeRedeemed = CanBeRedeemed(bond);
        isPremature = IsPremature(bond.maturityTime);
    }
    
    function BondInfoById(uint32 bondId) 
        public view 
        returns(
            bool canBeRedeemed,
            bool isPremature
            ) 
    {
        var bond = Bonds[bondId];
        
        canBeRedeemed = CanBeRedeemed(bond);
        isPremature = IsPremature(bond.maturityTime);
    }
    
     
     
    function AdmChange_README(string value) public
    {
        require(msg.sender == Founder);
        
        README = value;
    }
}
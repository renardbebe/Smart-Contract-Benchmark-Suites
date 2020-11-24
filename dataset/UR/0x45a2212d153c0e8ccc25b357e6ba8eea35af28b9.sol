 

library OwnershipTypes{
    using Serializer for Serializer.DataComponent;

    struct Ownership
    {
        address m_Owner;  
        uint32 m_OwnerInventoryIndex;  
    }

    function SerializeOwnership(Ownership ownership) internal pure returns (bytes32)
    {
        Serializer.DataComponent memory data;
        data.WriteAddress(0, ownership.m_Owner);
        data.WriteUint32(20, ownership.m_OwnerInventoryIndex);

        return data.m_Raw;
    }

    function DeserializeOwnership(bytes32 raw) internal pure returns (Ownership)
    {
        Ownership memory ownership;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        ownership.m_Owner = data.ReadAddress(0);
        ownership.m_OwnerInventoryIndex = data.ReadUint32(20);

        return ownership;
    }
}
library LibStructs{
    using Serializer for Serializer.DataComponent;
     

    struct Hero {
        uint16 stockID;
        uint8 rarity;
        uint16 hp;
        uint16 atk;
        uint16 def;
        uint16 agi;
        uint16 intel;
        uint16 cHp;
         
         
         
         
         

        uint8 isForSale;
        uint8 lvl;
        uint16 xp;
    }
    struct StockHero {uint16 price;uint8 stars;uint8 mainOnePosition;uint8 mainTwoPosition;uint16 stock;uint8 class;}

    function SerializeHero(Hero hero) internal pure returns (bytes32){
        Serializer.DataComponent memory data;
        data.WriteUint16(0, hero.stockID);
        data.WriteUint8(2, hero.rarity);
         
         
        data.WriteUint16(4, hero.hp);
        data.WriteUint16(6, hero.atk);
        data.WriteUint16(8, hero.def);
        data.WriteUint16(10, hero.agi);
        data.WriteUint16(12, hero.intel);
        data.WriteUint16(14, hero.cHp);

         
         
         
         

        data.WriteUint8(20, hero.isForSale);
        data.WriteUint8(21, hero.lvl);
        data.WriteUint16(23, hero.xp);

        return data.m_Raw;
    }
    function DeserializeHero(bytes32 raw) internal pure returns (Hero){
        Hero memory hero;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        hero.stockID = data.ReadUint16(0);
         
        hero.rarity = data.ReadUint8(2);
         
        hero.hp = data.ReadUint16(4);
        hero.atk = data.ReadUint16(6);
        hero.def = data.ReadUint16(8);
        hero.agi = data.ReadUint16(10);
        hero.intel = data.ReadUint16(12);
        hero.cHp = data.ReadUint16(14);

         
         
         
         

        hero.isForSale = data.ReadUint8(20);
        hero.lvl = data.ReadUint8(21);
        hero.xp = data.ReadUint16(23);

        return hero;
    }
    function SerializeStockHero(StockHero stockhero) internal pure returns (bytes32){
         

        Serializer.DataComponent memory data;
        data.WriteUint16(0, stockhero.price);
        data.WriteUint8(2, stockhero.stars);
        data.WriteUint8(3, stockhero.mainOnePosition);
        data.WriteUint8(4, stockhero.mainTwoPosition);
        data.WriteUint16(5, stockhero.stock);
        data.WriteUint8(7, stockhero.class);


        return data.m_Raw;
    }
    function DeserializeStockHero(bytes32 raw) internal pure returns (StockHero){
        StockHero memory stockhero;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        stockhero.price = data.ReadUint16(0);
        stockhero.stars = data.ReadUint8(2);
        stockhero.mainOnePosition = data.ReadUint8(3);
        stockhero.mainTwoPosition = data.ReadUint8(4);
        stockhero.stock = data.ReadUint16(5);
        stockhero.class = data.ReadUint8(7);

        return stockhero;
    }
     
    struct Item {
        uint16 stockID;
        uint8 lvl;
        uint8 rarity;
        uint16 hp;
        uint16 atk;
        uint16 def;
        uint16 agi;
        uint16 intel;

        uint8 critic;
        uint8 healbonus;
        uint8 atackbonus;
        uint8 defensebonus;

        uint8 isForSale;
        uint8 grade;
    }
    struct StockItem {uint16 price;uint8 stars;uint8 lvl;uint8 mainOnePosition;uint8 mainTwoPosition;uint16[5] stats;uint8[4] secstats;uint8 cat;uint8 subcat;}  

    function SerializeItem(Item item) internal pure returns (bytes32){
        Serializer.DataComponent memory data;

        data.WriteUint16(0, item.stockID);
        data.WriteUint8(4, item.lvl);
        data.WriteUint8(5, item.rarity);
        data.WriteUint16(6, item.hp);
        data.WriteUint16(8, item.atk);
        data.WriteUint16(10, item.def);
        data.WriteUint16(12, item.agi);
        data.WriteUint16(14, item.intel);
         

        data.WriteUint8(16, item.critic);
        data.WriteUint8(17, item.healbonus);
        data.WriteUint8(18, item.atackbonus);
        data.WriteUint8(19, item.defensebonus);

        data.WriteUint8(20, item.isForSale);
        data.WriteUint8(21, item.grade);


        return data.m_Raw;

    }
    function DeserializeItem(bytes32 raw) internal pure returns (Item){
        Item memory item;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        item.stockID = data.ReadUint16(0);

        item.lvl = data.ReadUint8(4);
        item.rarity = data.ReadUint8(5);
        item.hp = data.ReadUint16(6);
        item.atk = data.ReadUint16(8);
        item.def = data.ReadUint16(10);
        item.agi = data.ReadUint16(12);
        item.intel = data.ReadUint16(14);

        item.critic = data.ReadUint8(16);
        item.healbonus = data.ReadUint8(17);
        item.atackbonus = data.ReadUint8(18);
        item.defensebonus = data.ReadUint8(19);

        item.isForSale = data.ReadUint8(20);
        item.grade = data.ReadUint8(21);


        return item;
    }
    function SerializeStockItem(StockItem stockitem) internal pure returns (bytes32){
         
         

        Serializer.DataComponent memory data;
        data.WriteUint16(0, stockitem.price);
        data.WriteUint8(2, stockitem.stars);
        data.WriteUint8(3, stockitem.lvl);
        data.WriteUint8(4, stockitem.mainOnePosition);
        data.WriteUint8(5, stockitem.mainTwoPosition);
         
         
        data.WriteUint16(6, stockitem.stats[0]);
        data.WriteUint16(8, stockitem.stats[1]);
        data.WriteUint16(10, stockitem.stats[2]);
        data.WriteUint16(12, stockitem.stats[3]);
        data.WriteUint16(14, stockitem.stats[4]);
         
        data.WriteUint8(16, stockitem.secstats[0]);
        data.WriteUint8(17, stockitem.secstats[1]);
        data.WriteUint8(18, stockitem.secstats[2]);
        data.WriteUint8(19, stockitem.secstats[3]);

        data.WriteUint8(20, stockitem.cat);
        data.WriteUint8(21, stockitem.subcat);


        return data.m_Raw;
    }
    function DeserializeStockItem(bytes32 raw) internal pure returns (StockItem){
        StockItem memory stockitem;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        stockitem.price = data.ReadUint16(0);
        stockitem.stars = data.ReadUint8(2);
        stockitem.lvl = data.ReadUint8(3);
        stockitem.mainOnePosition = data.ReadUint8(4);
        stockitem.mainTwoPosition = data.ReadUint8(5);
         

        stockitem.stats[0] = data.ReadUint16(6);
        stockitem.stats[1] = data.ReadUint16(8);
        stockitem.stats[2] = data.ReadUint16(10);
        stockitem.stats[3] = data.ReadUint16(12);
        stockitem.stats[4] = data.ReadUint16(14);

        stockitem.secstats[0] = data.ReadUint8(16);
        stockitem.secstats[1] = data.ReadUint8(17);
        stockitem.secstats[2] = data.ReadUint8(18);
        stockitem.secstats[3] = data.ReadUint8(19);

        stockitem.cat = data.ReadUint8(20);
        stockitem.subcat = data.ReadUint8(21);

        return stockitem;
    }

    struct Action {uint16 actionID;uint8 actionType;uint16 finneyCost;uint32 cooldown;uint8 lvl;uint8 looted;uint8 isDaily;}
    function SerializeAction(Action action) internal pure returns (bytes32){
        Serializer.DataComponent memory data;
        data.WriteUint16(0, action.actionID);
        data.WriteUint8(2, action.actionType);
        data.WriteUint16(3, action.finneyCost);
        data.WriteUint32(5, action.cooldown);
        data.WriteUint8(9, action.lvl);
        data.WriteUint8(10, action.looted);
        data.WriteUint8(11, action.isDaily);

        return data.m_Raw;
    }
    function DeserializeAction(bytes32 raw) internal pure returns (Action){
        Action memory action;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        action.actionID = data.ReadUint16(0);
        action.actionType = data.ReadUint8(2);
        action.finneyCost = data.ReadUint16(3);
        action.cooldown = data.ReadUint32(5);
        action.lvl = data.ReadUint8(9);
        action.looted = data.ReadUint8(10);
        action.isDaily = data.ReadUint8(11);

        return action;
    }

    struct Mission {uint8 dificulty;uint16[4] stockitemId_drops;uint16[5] statsrequired;uint16 count;}
    function SerializeMission(Mission mission) internal pure returns (bytes32){
        Serializer.DataComponent memory data;
        data.WriteUint8(0, mission.dificulty);
        data.WriteUint16(1, mission.stockitemId_drops[0]);
        data.WriteUint16(5, mission.stockitemId_drops[1]);
        data.WriteUint16(9, mission.stockitemId_drops[2]);
        data.WriteUint16(13, mission.stockitemId_drops[3]);

        data.WriteUint16(15, mission.statsrequired[0]);
        data.WriteUint16(17, mission.statsrequired[1]);
        data.WriteUint16(19, mission.statsrequired[2]);
        data.WriteUint16(21, mission.statsrequired[3]);
        data.WriteUint16(23, mission.statsrequired[4]);

        data.WriteUint16(25, mission.count);

        return data.m_Raw;
    }
    function DeserializeMission(bytes32 raw) internal pure returns (Mission){
        Mission memory mission;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        mission.dificulty = data.ReadUint8(0);
        mission.stockitemId_drops[0] = data.ReadUint16(1);
        mission.stockitemId_drops[1] = data.ReadUint16(5);
        mission.stockitemId_drops[2] = data.ReadUint16(9);
        mission.stockitemId_drops[3] = data.ReadUint16(13);

        mission.statsrequired[0] = data.ReadUint16(15);
        mission.statsrequired[1] = data.ReadUint16(17);
        mission.statsrequired[2] = data.ReadUint16(19);
        mission.statsrequired[3] = data.ReadUint16(21);
        mission.statsrequired[4] = data.ReadUint16(23);

        mission.count = data.ReadUint16(25);

        return mission;
    }

    function toWei(uint80 price) public returns(uint256 value){
        value = price;
        value = value * 1 finney;

    }

}
library GlobalTypes{
    using Serializer for Serializer.DataComponent;

    struct Global
    {
        uint32 m_LastHeroId;  
        uint32 m_LastItem;  
        uint8 m_Unused8;  
        uint8 m_Unused9;  
        uint8 m_Unused10;  
        uint8 m_Unused11;  
    }

    function SerializeGlobal(Global global) internal pure returns (bytes32)
    {
        Serializer.DataComponent memory data;
        data.WriteUint32(0, global.m_LastHeroId);
        data.WriteUint32(4, global.m_LastItem);
        data.WriteUint8(8, global.m_Unused8);
        data.WriteUint8(9, global.m_Unused9);
        data.WriteUint8(10, global.m_Unused10);
        data.WriteUint8(11, global.m_Unused11);

        return data.m_Raw;
    }

    function DeserializeGlobal(bytes32 raw) internal pure returns (Global)
    {
        Global memory global;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        global.m_LastHeroId = data.ReadUint32(0);
        global.m_LastItem = data.ReadUint32(4);
        global.m_Unused8 = data.ReadUint8(8);
        global.m_Unused9 = data.ReadUint8(9);
        global.m_Unused10 = data.ReadUint8(10);
        global.m_Unused11 = data.ReadUint8(11);

        return global;
    }


}
library MarketTypes{
    using Serializer for Serializer.DataComponent;

    struct MarketListing
    {
        uint128 m_Price;  
    }

    function SerializeMarketListing(MarketListing listing) internal pure returns (bytes32)
    {
        Serializer.DataComponent memory data;
        data.WriteUint128(0, listing.m_Price);

        return data.m_Raw;
    }

    function DeserializeMarketListing(bytes32 raw) internal pure returns (MarketListing)
    {
        MarketListing memory listing;

        Serializer.DataComponent memory data;
        data.m_Raw = raw;

        listing.m_Price = data.ReadUint128(0);

        return listing;
    }
}
library Serializer{
    struct DataComponent
    {
        bytes32 m_Raw;
    }

    function ReadUint8(DataComponent memory self, uint32 offset) internal pure returns (uint8)
    {
        return uint8((self.m_Raw >> (offset * 8)) & 0xFF);
    }

    function WriteUint8(DataComponent memory self, uint32 offset, uint8 value) internal pure
    {
        self.m_Raw |= (bytes32(value) << (offset * 8));
    }

    function ReadUint16(DataComponent memory self, uint32 offset) internal pure returns (uint16)
    {
        return uint16((self.m_Raw >> (offset * 8)) & 0xFFFF);
    }

    function WriteUint16(DataComponent memory self, uint32 offset, uint16 value) internal pure
    {
        self.m_Raw |= (bytes32(value) << (offset * 8));
    }

    function ReadUint32(DataComponent memory self, uint32 offset) internal pure returns (uint32)
    {
        return uint32((self.m_Raw >> (offset * 8)) & 0xFFFFFFFF);
    }

    function WriteUint32(DataComponent memory self, uint32 offset, uint32 value) internal pure
    {
        self.m_Raw |= (bytes32(value) << (offset * 8));
    }

    function ReadUint64(DataComponent memory self, uint32 offset) internal pure returns (uint64)
    {
        return uint64((self.m_Raw >> (offset * 8)) & 0xFFFFFFFFFFFFFFFF);
    }

    function WriteUint64(DataComponent memory self, uint32 offset, uint64 value) internal pure
    {
        self.m_Raw |= (bytes32(value) << (offset * 8));
    }

    function ReadUint80(DataComponent memory self, uint32 offset) internal pure returns (uint80)
    {
        return uint80((self.m_Raw >> (offset * 8)) & 0xFFFFFFFFFFFFFFFFFFFF);
    }

    function WriteUint80(DataComponent memory self, uint32 offset, uint80 value) internal pure
    {
        self.m_Raw |= (bytes32(value) << (offset * 8));
    }

    function ReadUint128(DataComponent memory self, uint128 offset) internal pure returns (uint128)
    {
        return uint128((self.m_Raw >> (offset * 8)) & 0xFFFFFFFFFFFFFFFFFFFF);
    }

    function WriteUint128(DataComponent memory self, uint32 offset, uint128 value) internal pure
    {
        self.m_Raw |= (bytes32(value) << (offset * 8));
    }

    function ReadAddress(DataComponent memory self, uint32 offset) internal pure returns (address)
    {
        return address((self.m_Raw >> (offset * 8)) & (
        (0xFFFFFFFF << 0)  |
        (0xFFFFFFFF << 32) |
        (0xFFFFFFFF << 64) |
        (0xFFFFFFFF << 96) |
        (0xFFFFFFFF << 128)
        ));
    }

    function WriteAddress(DataComponent memory self, uint32 offset, address value) internal pure
    {
        self.m_Raw |= (bytes32(value) << (offset * 8));
    }
}
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
library SafeMath32 {

     
    function mul(uint32 a, uint32 b) internal pure returns (uint32) {
        if (a == 0) {
            return 0;
        }
        uint32 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint32 a, uint32 b) internal pure returns (uint32) {
         
        uint32 c = a / b;
         
        return c;
    }

     
    function sub(uint32 a, uint32 b) internal pure returns (uint32) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint32 a, uint32 b) internal pure returns (uint32) {
        uint32 c = a + b;
        assert(c >= a);
        return c;
    }
}
library SafeMath16 {

     
    function mul(uint16 a, uint16 b) internal pure returns (uint16) {
        if (a == 0) {
            return 0;
        }
        uint16 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint16 a, uint16 b) internal pure returns (uint16) {
         
        uint16 c = a / b;
         
        return c;
    }

     
    function sub(uint16 a, uint16 b) internal pure returns (uint16) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint16 a, uint16 b) internal pure returns (uint16) {
        uint16 c = a + b;
        assert(c >= a);
        return c;
    }
}
library SafeMath8 {

     
    function mul(uint8 a, uint8 b) internal pure returns (uint8) {
        if (a == 0) {
            return 0;
        }
        uint8 c = a * b;
        assert(c / a == b);
        return c;
    }

     
    function div(uint8 a, uint8 b) internal pure returns (uint8) {
         
        uint8 c = a / b;
         
        return c;
    }

     
    function sub(uint8 a, uint8 b) internal pure returns (uint8) {
        assert(b <= a);
        return a - b;
    }

     
    function add(uint8 a, uint8 b) internal pure returns (uint8) {
        uint8 c = a + b;
        assert(c >= a);
        return c;
    }
}

contract ProfitManager
{
    address public m_Owner;
    bool public m_Paused;
    AbstractDatabase m_Database= AbstractDatabase(0x095cbb73c75d4e1c62c94e0b1d4d88f8194b1941);

    modifier NotWhilePaused()
    {
        require(m_Paused == false);
        _;
    }
    modifier OnlyOwner(){
    require(msg.sender == m_Owner);
    _;
}

    address constant NullAddress = 0;

     
    uint256 constant ProfitFundsCategory = 14;
    uint256 constant WithdrawalFundsCategory = 15;
    uint256 constant HeroMarketCategory = 16;
    
     
    uint256 constant ReferalCategory = 237;

    function ProfitManager() public {
    m_Owner = msg.sender;
    m_Paused = true;
}
    function Unpause() public OnlyOwner()
    {
        m_Paused = false;
    }

    function Pause() public OnlyOwner()
    {
        require(m_Paused == false);

        m_Paused = true;
    }

     
    function WithdrawProfitFunds(uint256 withdraw_amount, address beneficiary) public NotWhilePaused() OnlyOwner()
    {
        uint256 profit_funds = uint256(m_Database.Load(NullAddress, ProfitFundsCategory, 0));
        require(withdraw_amount > 0);
        require(withdraw_amount <= profit_funds);
        require(beneficiary != address(0));
        require(beneficiary != address(this));
        require(beneficiary != address(m_Database));

        profit_funds -= withdraw_amount;

        m_Database.Store(NullAddress, ProfitFundsCategory, 0, bytes32(profit_funds));

        m_Database.TransferFunds(beneficiary, withdraw_amount);
    }

     
    function WithdrawWinnings(uint256 withdraw_amount) public NotWhilePaused()
    {

        require(withdraw_amount > 0);

        uint256 withdrawal_funds = uint256(m_Database.Load(msg.sender, WithdrawalFundsCategory, 0));
        require(withdraw_amount <= withdrawal_funds);

        withdrawal_funds -= withdraw_amount;

        m_Database.Store(msg.sender, WithdrawalFundsCategory, 0, bytes32(withdrawal_funds));

        m_Database.TransferFunds(msg.sender, withdraw_amount);
    }

    function GetProfitFunds() view public OnlyOwner() returns (uint256 funds)
    {
        uint256 profit_funds = uint256(m_Database.Load(NullAddress, ProfitFundsCategory, 0));
        return profit_funds;
    }
    function GetWithdrawalFunds(address target) view public NotWhilePaused() returns (uint256 funds)
    {
        funds = uint256(m_Database.Load(target, WithdrawalFundsCategory, 0));
    }

}

contract AbstractDatabase
{
    function() public payable;
    function ChangeOwner(address new_owner) public;
    function ChangeOwner2(address new_owner) public;
    function Store(address user, uint256 category, uint256 slot, bytes32 data) public;
    function Load(address user, uint256 category, uint256 index) public view returns (bytes32);
    function TransferFunds(address target, uint256 transfer_amount) public;
    function getRandom(uint256 upper, uint8 seed) public returns (uint256 number);
}
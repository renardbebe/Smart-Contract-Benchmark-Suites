 

pragma solidity ^0.4.24;

contract ClearCoinAdExchange {
    
     
    event lineItemActivated(address indexed wallet);
    event lineItemDeactivated(address indexed wallet);
    event adSlotActivated(address indexed wallet);
    event adSlotDeactivated(address indexed wallet);
    event clickTracked(address indexed lineItem, address indexed adSlot);
    
    address owner;
    
    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(
            msg.sender == owner,
            "Only owner can call this function."
        );
        _;
    }

    function changeOwner(address new_owner) public onlyOwner {
        owner = new_owner;
    }

     
    struct LineItem {
        uint256 budget;           
        string destination_url;   
        uint256 max_cpc;          
        uint256 max_daily_spend;  
        uint256 creative_type;    
        uint256[] categories;     
        bool active;
    }
    
     
     
     
     
    mapping (address => LineItem) line_items;
    
    modifier lineItemExists {
        require(
            line_items[msg.sender].active,
            "This address has not created a line item."
        );
        _;
    }    
        
    function createLineItem(
        string destination_url,
        uint256 max_cpc,
        uint256 max_daily_spend,
        uint256 creative_type,
        uint256[] categories
    ) public {
        line_items[msg.sender] = LineItem({
            budget: 0,
            destination_url: destination_url,
            max_cpc: max_cpc,
            max_daily_spend: max_daily_spend,
            creative_type: creative_type,
            categories: categories,
            active: true
        });

        emit lineItemActivated(msg.sender);
    }
    
    function deactivateLineItem() public lineItemExists {
        line_items[msg.sender].active = false;
        
        emit lineItemDeactivated(msg.sender);
    }
    
    function activateLineItem() public lineItemExists {
        line_items[msg.sender].active = true;
        
        emit lineItemActivated(msg.sender);
    }


     
    struct AdSlot {
        string domain;           
        uint256 creative_type;   
        uint256 min_cpc;         
        uint256[] categories;    
        uint256 avg_ad_quality;  
        bool active;
    }
    
     
     
    mapping (address => AdSlot) ad_slots;
    
    modifier adSlotExists {
        require(
            ad_slots[msg.sender].active,
            "This address has not created an ad slot."
        );
        _;
    }
    
    function createAdSlot(
        string domain,
        uint256 creative_type,
        uint256 min_cpc,
        uint256[] categories
    ) public {
        ad_slots[msg.sender] = AdSlot({
            domain: domain,
            creative_type: creative_type,
            min_cpc: min_cpc,
            categories: categories,
            avg_ad_quality: 100,  
            active: true
        });

        emit adSlotActivated(msg.sender);
    }
    
    function deactivateAdSlot() public adSlotExists {
        ad_slots[msg.sender].active = false;
        
        emit adSlotDeactivated(msg.sender);
    }
    
    function activateAdSlot() public adSlotExists {
        ad_slots[msg.sender].active = true;
        
        emit adSlotActivated(msg.sender);
    }

     
    function trackClick(address line_item_address, address ad_slot_address) public onlyOwner {
        emit clickTracked(line_item_address, ad_slot_address);
    }
    
}
 

pragma solidity ^0.4.24;

contract EthGods {

     
    
    EthGodsName private eth_gods_name;
    function set_eth_gods_name_contract_address(address eth_gods_name_contract_address) public returns (bool) {
        require(msg.sender == admin);
        eth_gods_name = EthGodsName(eth_gods_name_contract_address);
        return true;
    }

    EthGodsDice private eth_gods_dice;
    function set_eth_gods_dice_contract_address(address eth_gods_dice_contract_address) public returns (bool) {
        require(msg.sender == admin);
        eth_gods_dice = EthGodsDice(eth_gods_dice_contract_address);
        return true;
    }
    
     
 
 
      
    
     
    bool private contract_created;  
    address private contract_address;  
    string private contact_email = "<a class="__cf_email__" data-cfemail="781d0c101f171c0b381f15191114561b1715" href="/cdn-cgi/l/email-protection">[email protected]</a>";
    string private official_url = "swarm-gateways.net/bzz:/ethgods.eth";

    address private  admin;  
    address private controller1 = 0xcA5A9Db0EF9a0Bf5C38Fc86fdE6CB897d9d86adD;  
    address private controller2 = 0x8396D94046a099113E5fe5CBad7eC95e96c2B796;  

    address private v_god = 0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359;
    uint private block_hash_duration = 255;  
    

     
    struct god {
        uint god_id;
        uint level;
        uint exp;
        uint pet_type; 
        uint pet_level;   
        uint listed;  
        uint invite_price;
        uint blessing_player_id;
        bool hosted_pray;  
        uint bid_eth;  
        
        uint credit;  
        uint count_amulets_generated;
        uint first_amulet_generated;
        uint count_amulets_at_hand;
        uint count_amulets_selling;
        uint amulets_start_id;
        uint amulets_end_id;
        
        uint count_token_orders;
        uint first_active_token_order;

        uint allowed_block;  
        
        uint block_number;  
        bytes32 gene;
        bool gene_created;
        bytes32 pray_hash;  

        uint inviter_id;  
        uint count_gods_invited;  
        
    }
    uint private count_gods = 0;  
    mapping(address => god) private gods;  
    mapping(uint => address) private gods_address;  

    uint [] private listed_gods;  
    uint private max_listed_gods = 10000;  

    uint private initial_invite_price = 0.02 ether;  
    uint private invite_price_increase = 0.02 ether;  
    uint private max_invite_price = 1000 ether;  
    uint private max_extra_eth = 0.001 ether;  

    uint private list_level = 10;  
    uint private max_gas_price = 100000000000;  
    
     
    struct amulet {
        uint god_id;
        address owner;
        uint level;
        uint bound_start_block; 
         
        uint start_selling_block;  
        uint price;  
         
    }
    uint private count_amulets = 0; 
    mapping(uint => amulet) private amulets;  
    uint private bound_duration = 9000;  
    uint private order_duration = 20000;  

     
    address private pray_host_god;  
    bool private pray_reward_top100;  
    uint private pray_start_block;  
    bool private rewarded_pray_winners = false;

    uint private count_hosted_gods;  
    mapping (uint => address) private bidding_gods;  
    uint private initializer_reward = 36;  
    
    mapping(uint => uint) private max_winners;   
    uint private min_pray_interval = 2000;  
    uint private min_pray_duration = 6000;  
    uint private max_pray_duration = 9000;  

    uint private count_waiting_prayers;
    mapping (uint => address) private waiting_prayers;  
    uint private waiting_prayer_index = 1;  

    mapping(uint => uint) private pk_positions;  
    mapping(uint => uint) private count_listed_winners;  
    mapping (uint => mapping(uint => address)) private listed_winners;  

    bool private reEntrancyMutex = false;  
    
    uint private pray_egses = 0;  
    uint private pray_egst = 0;   

    mapping(address => uint) egses_balances;
        

     
    string public name = "EthGodsToken";
    string public symbol = "EGST";
    uint8 public decimals = 18;  
    uint private _totalSupply;
    mapping(address => uint) balances;  
    mapping(address => mapping(address => uint)) allowed;
    uint private allowed_use_CD = 20;  
    

    struct token_order {
        uint id;
        uint start_selling_block;
        address seller;
        uint unit_price;
        uint egst_amount;
    }
    uint private count_token_orders = 0;
    mapping (uint => token_order) token_orders;
    uint private first_active_token_order = 0;

    uint private min_unit_price = 20;  
    uint private max_unit_price = 200;  
    uint private max_egst_amount = 1000000 ether;  
    uint private min_egst_amount = 0.00001 ether;  
 
 
     
    uint private count_rounds = 0;
    
    struct winner_log {  
        uint god_block_number;
        bytes32 block_hash; 
        address prayer;
        address previous_winner;
        uint prize;
        bool pk_result;
    }
    mapping (uint => uint) private count_rounds_winner_logs;
    mapping(uint => mapping(uint => winner_log)) private winner_logs;
    
    struct change_log {
        uint block_number;
        uint asset_type;  
        
         
             
             
             
        
         
             
             
             
        
        uint reason;  
        uint change_amount;
        uint after_amount;
        address _from;
        address _to;
    }
    mapping (uint => uint) private count_rounds_change_logs;
    mapping(uint => mapping(uint => change_log)) private change_logs;

     
  
    
     
    constructor () public {
        require (contract_created == false);
        contract_created = true;
        contract_address = address(this);
        admin = msg.sender;

        create_god(admin, 0);
        create_god(v_god, 0);
        gods[v_god].level = 10;
        enlist_god(v_god);
        
        max_winners[1] = 1;  
        max_winners[2] = 2;  
        max_winners[3] = 8;  
        max_winners[4] = 16;  
        max_winners[5] = 100;  

        _totalSupply = 6000000 ether;
        pray_egst = 1000 ether;
        balances[admin] = sub(_totalSupply, pray_egst);
  
        initialize_pray();
    }
    
     
    function finalize() public {
        require(msg.sender == admin && count_rounds <= 3);
        selfdestruct(admin); 
    }
    

    function () public payable {
        revert ();
    }   
     
     
         
     
    
    function get_controller () public view returns (address, address){
        require (msg.sender == admin || msg.sender == controller1  || msg.sender == controller2);
        return (controller1, controller2);
    }
    
    function set_controller (uint controller_index, address new_controller_address) public returns (bool){
        if (controller_index == 1){
            require(msg.sender == controller2);
            controller1 = new_controller_address;
        } else {
            require(msg.sender == controller1);
            controller2 = new_controller_address;            
        }
        return true;
    }
     
    function set_admin (address new_admin_address) public returns (bool) {
        require (msg.sender == controller1 || msg.sender == controller2);
         
         
        delete gods[admin];
        admin = new_admin_address;
        gods_address[0] = admin;
        gods[admin].god_id = 0;
        return true;
    }  
    
     
    function set_parameters (uint parameter_type, uint new_parameter) public returns (bool){
        require (msg.sender == admin);
        if (parameter_type == 1) {
            max_pray_duration = new_parameter;
        } else if (parameter_type == 2) {
            min_pray_duration = new_parameter;
        } else if (parameter_type == 3) {
            block_hash_duration = new_parameter;
        } else if (parameter_type == 4) {
            min_pray_interval = new_parameter;
        } else if (parameter_type == 5) {
            order_duration = new_parameter;
        } else if (parameter_type == 6) {
            bound_duration = new_parameter;
        } else if (parameter_type == 7) {
            initializer_reward = new_parameter;
        } else if (parameter_type == 8) {
            allowed_use_CD = new_parameter;
        } else if (parameter_type == 9) {
            min_unit_price = new_parameter;
        } else if (parameter_type == 10) {
            max_unit_price = new_parameter;
        } else if (parameter_type == 11) {
            max_listed_gods = new_parameter;
        } else if (parameter_type == 12) {
            max_gas_price = new_parameter;
        } else if (parameter_type == 13) {
            max_invite_price = new_parameter;
        } else if (parameter_type == 14) {
            min_egst_amount = new_parameter;
        } else if (parameter_type == 15) {
            max_egst_amount = new_parameter;
        } else if (parameter_type == 16) {
            max_extra_eth = new_parameter;
        }
        return true;
    }  
        
    function set_strings (uint string_type, string new_string) public returns (bool){
        require (msg.sender == admin);
        
        if (string_type == 1){
            official_url = new_string;
        } else if (string_type == 2){
            name = new_string;  
        } else if (string_type == 3){
            symbol = new_string;  
        }
        return true;
    }    
    
  
     
    function query_contract () public view returns(uint, uint, address, uint, string, uint, uint){
        return (count_gods,
                listed_gods.length, 
                admin,
                block_hash_duration,
                official_url,
                bound_duration,
                min_pray_interval
               );
    }
    
    
    function query_uints () public view returns (uint[7] uints){
        uints[0] = max_invite_price;
        uints[1] = list_level;
        uints[2] = max_pray_duration;
        uints[3] = min_pray_duration;
        uints[4] = initializer_reward;
        uints[5] = min_unit_price;
        uints[6] = max_unit_price;
        
        return uints;
    }
    
    
    function query_uints2 () public view returns (uint[6] uints){
        uints[0] = allowed_use_CD;
        uints[1] = max_listed_gods;
        uints[2] = max_gas_price;
        uints[3] = min_egst_amount;
        uints[4] = max_egst_amount;
        uints[5] = max_extra_eth;

        return uints;
    }
  
     

    
     
    
     
    function register_god (uint inviter_id) public returns (uint) {
        return create_god(msg.sender, inviter_id);
    }
    function create_god (address god_address, uint inviter_id) private returns(uint god_id){  
         
        if (gods[god_address].credit == 0) {  
            gods[god_address].credit = 1;  
            
            god_id = count_gods;  
            count_gods = add(count_gods, 1) ;
            gods_address[god_id] = god_address;
            gods[god_address].god_id = god_id;
                        
            if (god_id > 0){  
                add_exp(god_address, 100);
                set_inviter(inviter_id);
            }
            
            return god_id;
        }
    }
    
    function set_inviter (uint inviter_id) public returns (bool){
        if (inviter_id > 0 && gods_address[inviter_id] != address(0)
        && gods[msg.sender].inviter_id == 0
        && gods[gods_address[inviter_id]].inviter_id != gods[msg.sender].god_id){
            gods[msg.sender].inviter_id = inviter_id;
            address inviter_address = gods_address[inviter_id];
            gods[inviter_address].count_gods_invited = add(gods[inviter_address].count_gods_invited, 1);
            return true;
        }
    }

    function add_exp (address god_address, uint exp_up) private returns(uint new_level, uint new_exp) {  
        if (god_address == admin){
            return (0,0);
        }
        if (gods[god_address].god_id == 0){
            uint inviter_id = gods[god_address].inviter_id;
            create_god(god_address, inviter_id);
        }
        new_exp = add(gods[god_address].exp, exp_up);
        uint current_god_level = gods[god_address].level;
        uint level_up_exp;
        new_level = current_god_level;

        for (uint i=0;i<10;i++){  
            if (current_god_level < 99){
                level_up_exp = mul(10, add(new_level, 1));
            } else {
                level_up_exp = 1000;
            }
            if (new_exp >= level_up_exp){
                new_exp = sub(new_exp, level_up_exp);
                new_level = add(new_level, 1);
            } else {
                break;
            }
        }

        gods[god_address].exp = new_exp;

        if(new_level > current_god_level) {
            gods[god_address].level = new_level;
            if (gods[god_address].listed > 0) {
                if (listed_gods.length > 1) {
                    sort_gods(gods[god_address].god_id);
                }
            } else if (new_level >= list_level && listed_gods.length < max_listed_gods) {
                enlist_god(god_address);
            }
        }
        
        return (new_level, new_exp);
    }

   
    function enlist_god (address god_address) private returns (uint) {  
        require(gods[god_address].level >= list_level && god_address != admin);
                
         
        if (gods[god_address].listed == 0) {
            uint god_id = gods[god_address].god_id;
            if (god_id == 0){
                god_id = create_god(god_address, 0);  
            }
            gods[god_address].listed = listed_gods.push(god_id);  
            gods[god_address].invite_price = initial_invite_price;

            list_level = add(list_level, 1);
            bidding_gods[listed_gods.length] = god_address;
            
        }
        return list_level;
    }
    
    function sort_gods_admin(uint god_id) public returns (bool){
        require (msg.sender == admin);
        sort_gods(god_id);
        return true;
    }


     
    function sort_gods (uint god_id) private returns (uint){ 
        require (god_id > 0);
        uint list_length = listed_gods.length;
        if (list_length > 1) {
            address god_address = gods_address[god_id];
            uint this_god_listed = gods[god_address].listed;
            if (this_god_listed < list_length) {
                uint higher_god_listed = add(this_god_listed, 1);
                uint higher_god_id = listed_gods[sub(higher_god_listed, 1)];
                address higher_god = gods_address[higher_god_id];
                if(gods[god_address].level > gods[higher_god].level
                || (gods[god_address].level == gods[higher_god].level
                    && gods[god_address].exp > gods[higher_god].exp)){
                        listed_gods[sub(this_god_listed, 1)] = higher_god_id;
                        listed_gods[sub(higher_god_listed, 1)] = god_id;
                        gods[higher_god].listed = this_god_listed;
                        gods[god_address].listed = higher_god_listed;
                }
            }
        }
        return gods[god_address].listed;
    }


    function burn_gas (uint god_id) public returns (uint god_new_level, uint god_new_exp) {
        address god_address = gods_address[god_id];
        require(god_id > 0 
                && god_id <= count_gods
                && gods[god_address].listed > 0);

        add_exp(god_address, 1);
        add_exp(msg.sender, 1);
        return (gods[god_address].level, gods[god_address].exp);  
    }


    function invite (uint god_id) public payable returns (uint new_invite_price)  {
        address god_address = gods_address[god_id];
        require(god_id > 0 
                && god_id <= count_gods
                && gods[god_address].hosted_pray == true
                && tx.gasprice <= max_gas_price
                );

        uint invite_price = gods[god_address].invite_price;

        require(msg.value >= invite_price); 

        if (gods[god_address].invite_price < max_invite_price) {
            gods[god_address].invite_price = add(invite_price, invite_price_increase);
        }
        
        uint exp_up = div(invite_price, (10 ** 15));  
        add_exp(god_address, exp_up);
        add_exp(msg.sender, exp_up);
       
         
        count_amulets ++;
        amulets[count_amulets].god_id = god_id;
        amulets[count_amulets].owner = msg.sender;

        gods[god_address].count_amulets_generated = add(gods[god_address].count_amulets_generated, 1);
        if (gods[god_address].count_amulets_generated == 1){
            gods[god_address].first_amulet_generated = count_amulets;
        }
        gods[msg.sender].count_amulets_at_hand = add(gods[msg.sender].count_amulets_at_hand, 1);
        update_amulets_count(msg.sender, count_amulets, true);

         
         
         
         
         
        pray_egses = add(pray_egses, div(mul(50, invite_price), 100)); 
        egses_from_contract(god_address, div(mul(10, invite_price), 100), 2);  
        egses_from_contract(gods_address[gods[god_address].blessing_player_id], div(mul(20, invite_price), 100), 2);  
        gods[god_address].blessing_player_id = gods[msg.sender].god_id;

        reward_inviter(msg.sender, invite_price);
        emit invited_god (msg.sender, god_id);

        return gods[god_address].invite_price;
    }
    event invited_god (address msg_sender, uint god_id);
    

    function reward_inviter (address inviter_address, uint invite_price) private returns (bool){
         
        uint previous_share = 0;
        uint inviter_share = 0;
        uint share_diff;
         
        
        for (uint i = 0; i < 9; i++){  
            if (inviter_address != address(0) && inviter_address != admin){  
                share_diff = 0;
                 
                gods[inviter_address].credit = add(gods[inviter_address].credit, invite_price);
                inviter_share = get_vip_level(inviter_address);

                if (inviter_share > previous_share) {
                    share_diff = sub(inviter_share, previous_share);
                    if (share_diff > 18) {
                        share_diff = 18;
                    }
                    previous_share = inviter_share;
                }
                
                if (share_diff > 0) {
                    egses_from_contract(inviter_address, div(mul(share_diff, invite_price), 100), 3);  
                }
                
                inviter_address = gods_address[gods[inviter_address].inviter_id];  
            } else{
                break;
            }
        }
         
        share_diff = sub(20, inviter_share); 
        egses_from_contract(admin, div(mul(share_diff, invite_price), 100), 2);  
        
        return true;
    }
    

    function upgrade_pet () public returns(bool){
         
        uint egst_cost = mul(add(gods[msg.sender].pet_level, 1), 10 ether);
        egst_to_contract(msg.sender, egst_cost, 6); 
        gods[msg.sender].pet_level = add(gods[msg.sender].pet_level, 1);
        add_exp(msg.sender, div(egst_cost, 1 ether));
        pray_egst = add(pray_egst, egst_cost);

         
         
        emit upgradeAmulet(msg.sender, 0, gods[msg.sender].pet_level);
        
        return true;
    }
    event upgradeAmulet (address owner, uint amulet_id, uint new_level);

    function set_pet_type (uint new_type) public returns (bool){
        if (gods[msg.sender].pet_type != new_type) {
            gods[msg.sender].pet_type = new_type;
            return true;
        }
    }
  
      
    function get_vip_level (address god_address) public view returns (uint vip_level){
        uint inviter_credit = gods[god_address].credit;
        
        if (inviter_credit > 500 ether){
            vip_level = 18;
        } else if (inviter_credit > 200 ether){
            vip_level = 15;
        } else if (inviter_credit > 100 ether){
            vip_level = 12;
        } else if (inviter_credit > 50 ether){
            vip_level = 10;
        } else if (inviter_credit > 20 ether){
            vip_level = 8;
        } else if (inviter_credit > 10 ether){
            vip_level = 6;
        } else if (inviter_credit > 5 ether){
            vip_level = 5;
        } else if (inviter_credit > 2 ether){
            vip_level = 4;
        } else if (inviter_credit > 1 ether){
            vip_level = 3;
        } else if (inviter_credit > 0.5 ether){
            vip_level = 2;
        } else {
            vip_level = 1;
        }
        return vip_level;
    }


     
    
    function get_god_id (address god_address) public view returns (uint god_id){
        return gods[god_address].god_id;
    }
    
    
    function get_god_address(uint god_id) public view returns (address){
        return gods_address[god_id];
    }


    function get_god (uint god_id) public view returns(uint, string, uint, uint, uint, uint, uint) {
        address god_address = gods_address[god_id];
        string memory god_name;

        god_name = eth_gods_name.get_god_name(god_address);
        if (bytes(god_name).length == 0){
            god_name = "Unknown";
        }

        return (gods[god_address].god_id,
                god_name,
                gods[god_address].level,
                gods[god_address].exp,
                gods[god_address].invite_price,
                gods[god_address].listed,
                gods[god_address].blessing_player_id
                );
    }
    
    
    function get_god_info (address god_address) public view returns (uint, bytes32, bool, uint, uint, uint, bytes32){
        return (gods[god_address].block_number,
                gods[god_address].gene,
                gods[god_address].gene_created,
                gods[god_address].pet_type,
                gods[god_address].pet_level,
                gods[god_address].bid_eth,
                gods[god_address].pray_hash
                );
    }
    
    
    function get_god_hosted_pray (uint god_id) public view returns (bool){
        return gods[gods_address[god_id]].hosted_pray;
    }
    
    
    function get_my_info () public view returns(uint, uint, uint, uint, uint, uint, uint) {  

        return (gods[msg.sender].god_id,
                egses_balances[msg.sender],  
                balances[msg.sender],  
                get_vip_level(msg.sender),
                gods[msg.sender].credit,  
                gods[msg.sender].inviter_id,
                gods[msg.sender].count_gods_invited
                );
    }   

    
    function get_listed_gods (uint page_number) public view returns (uint[]){
        
        uint count_listed_gods = listed_gods.length;
        require(count_listed_gods <= mul(page_number, 20));
        
        uint[] memory tempArray = new uint[] (20);

        if (page_number < 1) {
            page_number = 1;
        } 

        for (uint i = 0; i < 20; i++){
            if(count_listed_gods > add(i, mul(20, sub(page_number, 1)))) {
                tempArray[i] = listed_gods[sub(sub(sub(count_listed_gods, i), 1), mul(20, sub(page_number, 1)))];
            } else {
                break;
            }
        }
        
        return tempArray;
    }


     
   
    function upgrade_amulet (uint amulet_id) public returns(uint){
        require(amulets[amulet_id].owner == msg.sender);
        uint egst_cost = mul(add(amulets[amulet_id].level, 1), 10 ether);
        egst_to_contract(msg.sender, egst_cost, 7); 
        pray_egst = add(pray_egst, egst_cost);
         
         
        
        amulets[amulet_id].level = add(amulets[amulet_id].level, 1);
        add_exp(msg.sender, div(egst_cost, 1 ether));
        emit upgradeAmulet(msg.sender, amulet_id, amulets[amulet_id].level);
        
        return amulets[amulet_id].level;
    }
    
    
    function create_amulet_order (uint amulet_id, uint price) public returns (uint) {
        require(msg.sender == amulets[amulet_id].owner
                && amulet_id >= 1 && amulet_id <= count_amulets
                && amulets[amulet_id].start_selling_block == 0
                && add(amulets[amulet_id].bound_start_block, bound_duration) < block.number
                && price > 0);

        amulets[amulet_id].start_selling_block = block.number;
        amulets[amulet_id].price = price;
        gods[msg.sender].count_amulets_at_hand = sub(gods[msg.sender].count_amulets_at_hand, 1);
        gods[msg.sender].count_amulets_selling = add(gods[msg.sender].count_amulets_selling, 1);
        
        return gods[msg.sender].count_amulets_selling;

    }

    function buy_amulet (uint amulet_id) public payable returns (bool) {
        uint price = amulets[amulet_id].price;
        require(msg.value >= price && msg.value < add(price, max_extra_eth)
        && amulets[amulet_id].start_selling_block > 0
        && amulets[amulet_id].owner != msg.sender
        && price > 0);
        
        address seller = amulets[amulet_id].owner;
        amulets[amulet_id].owner = msg.sender;
        amulets[amulet_id].bound_start_block = block.number;
        amulets[amulet_id].start_selling_block = 0;

        gods[msg.sender].count_amulets_at_hand++;
        update_amulets_count(msg.sender, amulet_id, true);
        gods[seller].count_amulets_selling--;
        update_amulets_count(seller, amulet_id, false);

        egses_from_contract(seller, price, 6);  

        return true;
    }

    function withdraw_amulet_order (uint amulet_id) public returns (uint){
         
        require(msg.sender == amulets[amulet_id].owner
                && amulet_id >= 1 && amulet_id <= count_amulets
                && amulets[amulet_id].start_selling_block > 0);
                
        amulets[amulet_id].start_selling_block = 0;
        gods[msg.sender].count_amulets_at_hand++;
        gods[msg.sender].count_amulets_selling--;

        return gods[msg.sender].count_amulets_selling;
    }
    
    function update_amulets_count (address god_address, uint amulet_id, bool obtained) private returns (uint){
        if (obtained == true){
            if (amulet_id < gods[god_address].amulets_start_id) {
                gods[god_address].amulets_start_id = amulet_id;
            }
        } else {
            if (amulet_id == gods[god_address].amulets_start_id){
                for (uint i = amulet_id; i <= count_amulets; i++){
                    if (amulets[i].owner == god_address && i > amulet_id){
                        gods[god_address].amulets_start_id = i;
                        break;
                    }
                }
            }
        }
        return gods[god_address].amulets_start_id;
    }
    

    function get_amulets_generated (uint god_id) public view returns (uint[]) {
        address god_address = gods_address[god_id];
        uint count_amulets_generated = gods[god_address].count_amulets_generated;
        
        uint [] memory temp_list = new uint[](count_amulets_generated);
        uint count_elements = 0;
        for (uint i = gods[god_address].first_amulet_generated; i <= count_amulets; i++){
            if (amulets[i].god_id == god_id){
                temp_list [count_elements] = i;
                count_elements++;
                
                if (count_elements >= count_amulets_generated){
                    break;
                }
            }
        }
        return temp_list;
    }

    
    function get_amulets_at_hand (address god_address) public view returns (uint[]) {
        uint count_amulets_at_hand = gods[god_address].count_amulets_at_hand;
        uint [] memory temp_list = new uint[] (count_amulets_at_hand);
        uint count_elements = 0;
        for (uint i = gods[god_address].amulets_start_id; i <= count_amulets; i++){
            if (amulets[i].owner == god_address && amulets[i].start_selling_block == 0){
                temp_list[count_elements] = i;
                count_elements++;
                
                if (count_elements >= count_amulets_at_hand){
                    break;
                }
            }
        }

        return temp_list;
    }
    
    
    function get_my_amulets_selling () public view returns (uint[]){

        uint count_amulets_selling = gods[msg.sender].count_amulets_selling;
        uint [] memory temp_list = new uint[] (count_amulets_selling);
        uint count_elements = 0;
        for (uint i = gods[msg.sender].amulets_start_id; i <= count_amulets; i++){
            if (amulets[i].owner == msg.sender 
            && amulets[i].start_selling_block > 0){
                temp_list[count_elements] = i;
                count_elements++;
                
                if (count_elements >= count_amulets_selling){
                    break;
                }
            }
        }

        return temp_list;
    }

     
    function get_amulet_orders_overview () public view returns(uint){
        uint count_amulets_selling = 0;
        for (uint i = 1; i <= count_amulets; i++){
            if (add(amulets[i].start_selling_block, order_duration) > block.number && amulets[i].owner != msg.sender){
                count_amulets_selling ++;
            }
        }        
        
        return count_amulets_selling;  
    }

    function get_amulet_orders (uint page_number) public view returns (uint[]){
        uint[] memory temp_list = new uint[] (20);
        uint count_amulets_selling = 0;
        uint count_list_elements = 0;

        if ((page_number < 1)
            || count_amulets  <= 20) {
            page_number = 1;  
        }
        uint start_amulets_count = mul(sub(page_number, 1), 20);

        for (uint i = 1; i <= count_amulets; i++){
            if (add(amulets[i].start_selling_block, order_duration) > block.number && amulets[i].owner != msg.sender){
                
                if (count_amulets_selling <= start_amulets_count) {
                    count_amulets_selling ++;
                }
                if (count_amulets_selling > start_amulets_count){
                    
                    temp_list[count_list_elements] = i;
                    count_list_elements ++;
                    
                    if (count_list_elements >= 20){
                        break;
                    }
                }
                
            }
        }
        
        return temp_list;
    }
    
    
    function get_amulet (uint amulet_id) public view returns(address, string, uint, uint, uint, uint, uint){
        uint god_id = amulets[amulet_id].god_id;
         
        string memory god_name = eth_gods_name.get_god_name(gods_address[god_id]);
        uint god_level = gods[gods_address[god_id]].level;
        uint amulet_level = amulets[amulet_id].level;
        uint start_selling_block = amulets[amulet_id].start_selling_block;
        uint price = amulets[amulet_id].price;

        return(amulets[amulet_id].owner,
                god_name,
                god_id,
                god_level,
                amulet_level,
                start_selling_block,
                price
              );
    }

    function get_amulet2 (uint amulet_id) public view returns(uint){
        return amulets[amulet_id].bound_start_block;
    }

     
    
     
    function admin_deposit (uint egst_amount) public payable returns (bool) {
        require (msg.sender == admin);
        if (msg.value > 0){
            pray_egses = add(pray_egses, msg.value);
            egses_from_contract(admin, msg.value, 4);  
        }
        if (egst_amount > 0){
            pray_egst = add(pray_egst, egst_amount);
            egst_to_contract(admin, egst_amount, 4);  
        }
        return true;
    }
        
    function initialize_pray () private returns (bool){
        if (pray_start_block > 0) {
            require (check_event_completed() == true
            && rewarded_pray_winners == true);
        }
        
        count_rounds = add(count_rounds, 1);
        count_rounds_winner_logs[count_rounds] = 0;
        pray_start_block = block.number;
        rewarded_pray_winners = false;

        for (uint i = 1; i <= 5; i++){
            pk_positions[i] = max_winners[i];  
			count_listed_winners[i] = 0;
        }
        if (listed_gods.length > count_hosted_gods) {
             
            count_hosted_gods = add(count_hosted_gods, 1);
            pray_host_god = bidding_gods[count_hosted_gods];
            gods[pray_host_god].hosted_pray = true;
            pray_reward_top100 = true;
        } else {
             
            (uint highest_bid, address highest_bidder) = compare_bid_eth();

            gods[highest_bidder].bid_eth = 0;
            pray_host_god = highest_bidder;
            pray_egses = add(pray_egses, highest_bid);
            pray_reward_top100 = false;

        }
        return true;

    }


    function bid_host () public payable returns (bool) {
        require (msg.value > 0 && gods[msg.sender].listed > 0);
        gods[msg.sender].bid_eth = add (gods[msg.sender].bid_eth, msg.value);

        return true;
    }
    

    function withdraw_bid () public returns (bool) {
        require(gods[msg.sender].bid_eth > 0);
        gods[msg.sender].bid_eth = 0;
        egses_from_contract(msg.sender, gods[msg.sender].bid_eth, 8);  
        return true;
    }
    
    
     
    function pray_create (uint inviter_id) public returns (bool) {
         
        create_god(msg.sender, inviter_id);
        pray();
    }
    
     
    function pray () public returns (bool){
        require (add(gods[msg.sender].block_number, min_pray_interval) < block.number
        && tx.gasprice <= max_gas_price
        && check_event_completed() == false);

        if (waiting_prayer_index <= count_waiting_prayers) {

            address waiting_prayer = waiting_prayers[waiting_prayer_index];
            uint god_block_number = gods[waiting_prayer].block_number;
            bytes32 block_hash;
            
            if ((add(god_block_number, 1)) < block.number) { 

                if (add(god_block_number, block_hash_duration) < block.number) { 
                    gods[waiting_prayer].block_number = block.number;  
                     
                    count_waiting_prayers = add(count_waiting_prayers, 1);
                    waiting_prayers[count_waiting_prayers] = waiting_prayer;
                } else { 
                    block_hash = keccak256(abi.encodePacked(blockhash(add(god_block_number, 1))));
                    if(gods[waiting_prayer].gene_created == false){
                        gods[waiting_prayer].gene = block_hash;
                        gods[waiting_prayer].gene_created = true;
                    }
                    gods[waiting_prayer].pray_hash = block_hash;
    
                    uint dice_result = eth_gods_dice.throw_dice (block_hash)[0];

                    if (dice_result >= 1 && dice_result <= 5){
                        set_winner(dice_result, waiting_prayer, block_hash, god_block_number);
                    }
                }
                waiting_prayer_index = add(waiting_prayer_index, 1);
            }
        }
        
        count_waiting_prayers = add(count_waiting_prayers, 1);
        waiting_prayers[count_waiting_prayers] = msg.sender;

        gods[msg.sender].block_number = block.number;
        gods[msg.sender].pray_hash = 0x0;
        add_exp(msg.sender, 1);
        add_exp(pray_host_god, 1);

        return true;
    }


    function set_winner (uint prize, address waiting_prayer, bytes32 block_hash, uint god_block_number) private returns (uint){

        count_rounds_winner_logs[count_rounds] = add(count_rounds_winner_logs[count_rounds], 1);
        winner_logs[count_rounds][count_rounds_winner_logs[count_rounds]].god_block_number = god_block_number;
        winner_logs[count_rounds][count_rounds_winner_logs[count_rounds]].block_hash = block_hash;
        winner_logs[count_rounds][count_rounds_winner_logs[count_rounds]].prayer = waiting_prayer;
        winner_logs[count_rounds][count_rounds_winner_logs[count_rounds]].prize = prize;

        if (count_listed_winners[prize] >= max_winners[prize]){  
           	uint pk_position = pk_positions[prize];
        	address previous_winner = listed_winners[prize][pk_position];  

            bool pk_result = pk(waiting_prayer, previous_winner, block_hash);

			winner_logs[count_rounds][count_rounds_winner_logs[count_rounds]].pk_result = pk_result;
			winner_logs[count_rounds][count_rounds_winner_logs[count_rounds]].previous_winner = previous_winner;
            
            if (pk_result == true) {
                listed_winners[prize][pk_position] = waiting_prayer;  
            }
            if (prize > 1) {  
                if (pk_positions[prize] > 1){
                    pk_positions[prize] = sub(pk_positions[prize], 1);
                } else {
                    pk_positions[prize] = max_winners[prize];
                }               
            }
        } else {
            count_listed_winners[prize] = add(count_listed_winners[prize], 1);
            listed_winners[prize][count_listed_winners[prize]] = waiting_prayer;
        }
     
        return count_listed_winners[prize];
    }

    function reward_pray_winners () public returns (bool){
        require (check_event_completed() == true);

        uint this_reward_egses;
        uint reward_pool_egses = div(pray_egses, 10);
        pray_egses = sub(pray_egses, reward_pool_egses);
        uint this_reward_egst;
        uint reward_pool_egst = div(pray_egst, 10);
        pray_egst = sub(pray_egst, reward_pool_egst);  
        
        egst_from_contract(pray_host_god, mul(div(reward_pool_egst, 100), 60), 1);  
        
        for (uint i = 1; i<=5; i++){
            this_reward_egses = 0;
            this_reward_egst = 0;
            if (i == 1) {
                this_reward_egses = mul(div(reward_pool_egses, 100), 60);
            } else if (i == 2){
                this_reward_egses = mul(div(reward_pool_egses, 100), 20);
            } else if (i == 3){
                this_reward_egst = mul(div(reward_pool_egst, 100), 3);
            } else if (i == 4){
                this_reward_egst = div(reward_pool_egst, 100);
            } 
            
            for (uint reward_i = 1; reward_i <= count_listed_winners[i]; reward_i++){
                address rewarding_winner = listed_winners[i][reward_i];

                if (this_reward_egses > 0 ) {
                    egses_from_contract(rewarding_winner, this_reward_egses, 1);  
                } else if (this_reward_egst > 0) {
                    egst_from_contract(rewarding_winner, this_reward_egst, 1);  
                }  
                
                add_exp(rewarding_winner, 6);
            }
        }
            
        
        if(pray_reward_top100 == true) {
            reward_top_gods();
        }
            
         
        egst_from_contract(msg.sender, mul(initializer_reward, 1 ether), 1);  
        _totalSupply = add(_totalSupply, mul(initializer_reward, 1 ether));  
        add_exp(msg.sender, initializer_reward);

        rewarded_pray_winners = true;
        initialize_pray();
        return true;
    }


     
    function reward_top_gods () private returns (bool){  
        
        uint count_listed_gods = listed_gods.length;
        uint last_god_index;
        
        if (count_listed_gods > 100) {
            last_god_index = sub(count_listed_gods, 100);
        } else {
            last_god_index = 0;
        }
        
        uint reward_egst = 0;
        uint base_reward = 6 ether;
        if (count_rounds == 6){
            base_reward = mul(base_reward, 6);
        }
        for (uint i = last_god_index; i < count_listed_gods; i++) {
            reward_egst = mul(base_reward, sub(add(i, 1), last_god_index));
            egst_from_contract(gods_address[listed_gods[i]], reward_egst, 2); 
            _totalSupply = add(_totalSupply, reward_egst);   
            if (gods[gods_address[listed_gods[i]]].blessing_player_id > 0){
                egst_from_contract(gods_address[gods[gods_address[listed_gods[i]]].blessing_player_id], reward_egst, 2); 
                _totalSupply = add(_totalSupply, reward_egst); 
            }
        }
        
        return true;
    }


    function compare_bid_eth () private view returns (uint, address) {
        uint highest_bid = 0;
        address highest_bidder = v_god;  

        for (uint j = 1; j <= listed_gods.length; j++){
            if (gods[bidding_gods[j]].bid_eth > highest_bid){
                highest_bid = gods[bidding_gods[j]].bid_eth;
                highest_bidder = bidding_gods[j];
            }
        }
        return (highest_bid, highest_bidder);
    }


    function check_event_completed () public view returns (bool){
         
        if (add(pray_start_block, max_pray_duration) > block.number){
            if (add(pray_start_block, min_pray_duration) < block.number){
                for (uint i = 1; i <= 5; i++){
                    if(count_listed_winners[i] < max_winners[i]){
                        return false;
                    }           
                }
                return true;
            } else {
                return false;
            }
            
        } else {
            return true;   
        }
    }


    function pk (address attacker, address defender, bytes32 block_hash) public view returns (bool pk_result){ 

        (uint attacker_sum_god_levels, uint attacker_sum_amulet_levels) = get_sum_levels_pk(attacker);
        (uint defender_sum_god_levels, uint defender_sum_amulet_levels) = get_sum_levels_pk(defender);
    
        pk_result = eth_gods_dice.pk(block_hash, attacker_sum_god_levels, attacker_sum_amulet_levels, defender_sum_god_levels, defender_sum_amulet_levels);
        
        return pk_result;
    }
    
    
    function get_sum_levels_pk (address god_address) public view returns (uint sum_gods_level, uint sum_amulets_level){
             
        sum_gods_level =  gods[god_address].level;
        sum_amulets_level = gods[god_address].pet_level;  
		uint amulet_god_id;
        uint amulet_god_level;
        for (uint i = 1; i <= count_amulets; i++){
            if (amulets[i].owner == god_address && amulets[i].start_selling_block == 0){
                amulet_god_id = amulets[i].god_id;
                amulet_god_level = gods[gods_address[amulet_god_id]].level;
                sum_gods_level = add(sum_gods_level, amulet_god_level);
                sum_amulets_level = add(sum_amulets_level, amulets[i].level);
            }
        }
                
        return (sum_gods_level, sum_amulets_level);
    }
        
     
    function get_listed_winners (uint prize) public view returns (address[]){
        address [] memory temp_list = new address[] (count_listed_winners[prize]);
        for (uint i = 0; i < count_listed_winners[prize]; i++){
            temp_list[i] = listed_winners[prize][add(i,1)];
        }
        return temp_list;
    }

   
    function query_pray () public view returns (uint, uint, uint, address, address, uint, bool){
        (uint highest_bid, address highest_bidder) = compare_bid_eth();
        return (highest_bid, 
                pray_egses, 
                pray_egst, 
                pray_host_god, 
                highest_bidder,
                count_rounds,
                pray_reward_top100);
    }     
    

 
     

     

    function egses_from_contract (address to, uint tokens, uint reason) private returns (bool) {  
        if (reason == 1) {
            require (pray_egses > tokens);
            pray_egses = sub(pray_egses, tokens);
        }

        egses_balances[to] = add(egses_balances[to], tokens);

        create_change_log(1, reason, tokens, egses_balances[to], contract_address, to);
        return true;
    } 
    
    function egses_withdraw () public returns (uint tokens){
        tokens = egses_balances[msg.sender];
        require (tokens > 0 && contract_address.balance >= tokens && reEntrancyMutex == false);

        reEntrancyMutex = true;  
        egses_balances[msg.sender] = 0;
        msg.sender.transfer(tokens);
        reEntrancyMutex = false;
        
        emit withdraw_egses(msg.sender, tokens);
        create_change_log(1, 5, tokens, 0, contract_address, msg.sender);  

        return tokens;
    }
    event withdraw_egses (address receiver, uint tokens);

    
   

     
    function totalSupply () public view returns (uint){
        return _totalSupply;
    }


    function balanceOf (address tokenOwner) public view returns (uint){
        return balances[tokenOwner];  
    }

    function allowance (address tokenOwner, address spender) public view returns (uint) {
        return allowed[tokenOwner][spender];
    }

    function transfer (address to, uint tokens) public returns (bool success){
        require (balances[msg.sender] >= tokens);
        balances[msg.sender] = sub(balances[msg.sender], tokens);
        balances[to] = add(balances[to], tokens);
        emit Transfer(msg.sender, to, tokens);
        create_change_log(2, 9, tokens, balances[to], msg.sender, to);
        
        return true;    
    }
    event Transfer (address indexed from, address indexed to, uint tokens);


    function approve (address spender, uint tokens) public returns (bool success) {
         
         
        require (balances[msg.sender] >= tokens);
        if (tokens > 0){
            require (add(gods[msg.sender].allowed_block, allowed_use_CD) < block.number);
        }

        allowed[msg.sender][spender] = tokens;
        
        emit Approval(msg.sender, spender, tokens);
        return true;
    }
    event Approval (address indexed tokenOwner, address indexed spender, uint tokens);


    function transferFrom (address from, address to, uint tokens) public returns (bool success) {
        require (balances[from] >= tokens);
        allowed[from][msg.sender] = sub(allowed[from][msg.sender], tokens);
        balances[from] = sub(balances[from], tokens);
        balances[to] = add(balances[to], tokens);
        gods[from].allowed_block = block.number;
        
        emit Transfer(from, to, tokens);
        create_change_log(2, 10, tokens, balances[to], from, to);
        return true;    
    }

     
    
    
     
  
    function egst_from_contract (address to, uint tokens, uint reason) private returns (bool) {  
        balances[to] = add(balances[to], tokens);

        create_change_log(2, reason, tokens, balances[to], contract_address, to); 
        return true;
    }

    function egst_to_contract (address from, uint tokens, uint reason) private returns (bool) {  
        require (balances[from] >= tokens);
        balances[from] = sub(balances[from], tokens);
        

        emit spend_egst(from, tokens, reason);
        create_change_log(2, reason, tokens, balances[from], from, contract_address);
        return true;
    }
    event spend_egst (address from, uint tokens, uint reason);


    function create_token_order (uint unit_price, uint egst_amount) public returns (uint) {      
        require(unit_price >= min_unit_price && unit_price <= max_unit_price 
        && balances[msg.sender] >= egst_amount
        && egst_amount <= max_egst_amount
        && egst_amount >= min_egst_amount);

        count_token_orders = add(count_token_orders, 1);

        egst_to_contract(msg.sender, egst_amount, 3);  
        
        token_orders[count_token_orders].start_selling_block = block.number;    
        token_orders[count_token_orders].seller = msg.sender;
        token_orders[count_token_orders].unit_price = unit_price;
        token_orders[count_token_orders].egst_amount = egst_amount;
        gods[msg.sender].count_token_orders++;
        
        update_first_active_token_order(msg.sender);

        return gods[msg.sender].count_token_orders++;
    }


    function withdraw_token_order (uint order_id) public returns (bool) { 
        require (msg.sender == token_orders[order_id].seller
                && token_orders[order_id].egst_amount > 0);

        uint egst_amount = token_orders[order_id].egst_amount;
        token_orders[order_id].start_selling_block = 0;
        token_orders[order_id].egst_amount = 0;
         
        egst_from_contract(msg.sender, egst_amount, 4);  
        gods[msg.sender].count_token_orders = sub(gods[msg.sender].count_token_orders, 1);
        
        update_first_active_token_order(msg.sender);
        emit WithdrawTokenOrder(msg.sender, order_id);

        return true;
    }
    event WithdrawTokenOrder (address seller, uint order_id);

    function buy_token (uint order_id, uint egst_amount) public payable returns (uint) { 

        require(order_id >= first_active_token_order 
                && order_id <= count_token_orders
                && egst_amount <= token_orders[order_id].egst_amount
                && token_orders[order_id].egst_amount > 0);
        
         
        uint eth_cost = div(mul(token_orders[order_id].unit_price, egst_amount), 100000);
        require(msg.value >= eth_cost && msg.value < add(eth_cost, max_extra_eth) );

        token_orders[order_id].egst_amount = sub(token_orders[order_id].egst_amount, egst_amount);
        egst_from_contract(msg.sender, egst_amount, token_orders[order_id].unit_price);  
         
        
        address seller = token_orders[order_id].seller;
        egses_from_contract(seller, eth_cost, 7);  
        
        
        if (token_orders[order_id].egst_amount <= 0){
            token_orders[order_id].start_selling_block = 0;
            gods[seller].count_token_orders = sub(gods[seller].count_token_orders, 1);
            update_first_active_token_order(seller);
        }
        
        emit BuyToken(msg.sender, order_id, egst_amount);

        return token_orders[order_id].egst_amount;
    }
    event BuyToken (address buyer, uint order_id, uint egst_amount);

  
    function update_first_active_token_order (address god_address) private returns (uint, uint){  
        if (count_token_orders > 0 
        && first_active_token_order == 0){
            first_active_token_order = 1;
        } else {
            for (uint i = first_active_token_order; i <= count_token_orders; i++) {
                if (add(token_orders[i].start_selling_block, order_duration) > block.number){
                     
                    if (i > first_active_token_order){
                        first_active_token_order = i;
                    }
                    break;
                }
            }    
        }
            
        if (gods[god_address].count_token_orders > 0
        && gods[god_address].first_active_token_order == 0){
            gods[god_address].first_active_token_order = 1;  
        } else {
            for (uint j = gods[god_address].first_active_token_order; j < count_token_orders; j++){
                if (token_orders[j].seller == god_address 
                && token_orders[j].start_selling_block > 0){  
                     
                    if(j > gods[god_address].first_active_token_order){
                        gods[god_address].first_active_token_order = j;
                    }
                    break;
                }
            }
        }
        
        return (first_active_token_order, gods[msg.sender].first_active_token_order);
    }


    function get_token_order (uint order_id) public view returns(uint, address, uint, uint){
        require(order_id >= 1 && order_id <= count_token_orders);

        return(token_orders[order_id].start_selling_block,
               token_orders[order_id].seller,
               token_orders[order_id].unit_price,
               token_orders[order_id].egst_amount);
    }

     
    function get_token_orders () public view returns(uint, uint, uint, uint, uint) {
        uint lowest_price = max_unit_price;
        for (uint i = first_active_token_order; i <= count_token_orders; i++){
            if (token_orders[i].unit_price < lowest_price 
            && token_orders[i].egst_amount > 0
            && add(token_orders[i].start_selling_block, order_duration) > block.number){
                lowest_price = token_orders[i].unit_price;
            }
        }
        return (count_token_orders, first_active_token_order, order_duration, max_unit_price, lowest_price);
    }
    

    function get_my_token_orders () public view returns(uint []) {
        uint my_count_token_orders = gods[msg.sender].count_token_orders;
        uint [] memory temp_list = new uint[] (my_count_token_orders);
        uint count_list_elements = 0;
        for (uint i = gods[msg.sender].first_active_token_order; i <= count_token_orders; i++){
            if (token_orders[i].seller == msg.sender
            && token_orders[i].start_selling_block > 0){
                temp_list[count_list_elements] = i;
                count_list_elements++;
                
                if (count_list_elements >= my_count_token_orders){
                    break;
                }
            }
        }

        return temp_list;
    }


     
    
   
     
    function get_winner_log (uint pray_round, uint log_id) public view returns (uint, bytes32, address, address, uint, bool){
        require(log_id >= 1 && log_id <= count_rounds_winner_logs[pray_round]);
        winner_log storage this_winner_log = winner_logs[pray_round][log_id];
        return (this_winner_log.god_block_number,
                this_winner_log.block_hash,
                this_winner_log.prayer,
                this_winner_log.previous_winner,
                this_winner_log.prize,
                this_winner_log.pk_result);
    }    

    function get_count_rounds_winner_logs (uint pray_round) public view returns (uint){
        return count_rounds_winner_logs[pray_round];
    }


     
         
         
         
    
     
         
         
         
         

        
    function create_change_log (uint asset_type, uint reason, uint change_amount, uint after_amount, address _from, address _to) private returns (uint) {
        count_rounds_change_logs[count_rounds] = add(count_rounds_change_logs[count_rounds], 1);
        uint log_id = count_rounds_change_logs[count_rounds];
 
        change_logs[count_rounds][log_id].block_number = block.number;
        change_logs[count_rounds][log_id].asset_type = asset_type;
        change_logs[count_rounds][log_id].reason = reason;
        change_logs[count_rounds][log_id].change_amount = change_amount;
        change_logs[count_rounds][log_id].after_amount = after_amount; 
        change_logs[count_rounds][log_id]._from = _from;
        change_logs[count_rounds][log_id]._to = _to;
        
        return log_id;
    }
          
    function get_change_log (uint pray_round, uint log_id) public view returns (uint, uint, uint, uint, uint, address, address){  
        change_log storage this_log = change_logs[pray_round][log_id];
        return (this_log.block_number,
                this_log.asset_type,
                this_log.reason,  
                this_log.change_amount,
                this_log.after_amount,  
                this_log._from,
                this_log._to);
        
    }
    
    function get_count_rounds_change_logs (uint pray_round) public view returns(uint){
        return count_rounds_change_logs[pray_round];
    }
    
     


     

     function add (uint a, uint b) internal pure returns (uint c) {
         c = a + b;
         require(c >= a);
     }
     function sub (uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
         c = a - b;
     }
     function mul (uint a, uint b) internal pure returns (uint c) {
         c = a * b;
         require(a == 0 || c / a == b);
     }
     function div (uint a, uint b) internal pure returns (uint c) {
         require(b > 0);
         c = a / b;
     }

}

contract EthGodsDice {
    
     
    EthGods private eth_gods;
    address private ethgods_contract_address = address(0); 
    function set_eth_gods_contract_address(address eth_gods_contract_address) public returns (bool){
        require (msg.sender == admin);
        
        ethgods_contract_address = eth_gods_contract_address;
        eth_gods = EthGods(ethgods_contract_address); 
        return true;
    }
  
    address private admin;  
    uint private block_hash_duration;
    function update_admin () public returns (bool){
        (,,address new_admin, uint new_block_hash_duration,,,) = eth_gods.query_contract();
        require (msg.sender == new_admin);
        admin = new_admin;
        block_hash_duration = new_block_hash_duration;
        return true;
    }
        
     
    bool private contract_created;  
    address private contract_address;  
    
     
    constructor () public {
        require (contract_created == false);
        contract_created = true;
        contract_address = address(this);
        admin = msg.sender;

    }

    function finalize () public {
        require (msg.sender == admin);
        selfdestruct(msg.sender); 
    }
    
    function () public payable {
        revert();   
    }
    
     

    function tell_fortune_blockhash () public view returns (bytes32){
        bytes32 block_hash;
        (uint god_block_number,,,,,,) = eth_gods.get_god_info(msg.sender);
        if (god_block_number > 0
            && add(god_block_number, 1) < block.number
            && add(god_block_number, block_hash_duration) > block.number) {
            block_hash = keccak256(abi.encodePacked(blockhash(god_block_number + 1)));
        } else {
            block_hash = keccak256(abi.encodePacked(blockhash(block.number - 1)));
        }
        return block_hash;
    }
    
        
    function tell_fortune () public view returns (uint[]){
        bytes32 block_hash;
        (uint god_block_number,,,,,,) = eth_gods.get_god_info(msg.sender);
        if (god_block_number > 0
            && add(god_block_number, 1) < block.number
            && add(god_block_number, block_hash_duration) > block.number) {
            block_hash = keccak256(abi.encodePacked(blockhash(god_block_number + 1)));
        } else {
            block_hash = keccak256(abi.encodePacked(blockhash(block.number - 1)));
        }
        return throw_dice (block_hash);
    }

    
    function throw_dice (bytes32 block_hash) public pure returns (uint[]) { 
        uint[] memory dice_numbers = new uint[](7);
         
        uint hash_number;
        uint[] memory count_dice_numbers = new uint[](7);
         
        uint i;  
  
        for (i = 1; i <= 6; i++) {
            hash_number = uint(block_hash[i]);
             
            if (hash_number >= 214) {  
                dice_numbers[i] = 6;
            } else if (hash_number >= 172) {  
                dice_numbers[i] = 5;
            } else if (hash_number >= 129) {  
                dice_numbers[i] = 4;
            } else if (hash_number >= 86) {  
                dice_numbers[i] = 3;
            } else if (hash_number >= 43) {  
                dice_numbers[i] = 2;
            } else {
                dice_numbers[i] = 1;
            }
            count_dice_numbers[dice_numbers[i]] ++;
        }

        bool won_super_prize = false;
        uint count_super_eth = 0;
        for (i = 1; i <= 6; i++) {
            if (count_dice_numbers[i] >= 5) {
                dice_numbers[0] = 1;  
                won_super_prize = true;
                break;
            }else if (count_dice_numbers[i] == 4) {
                dice_numbers[0] = 3;  
                won_super_prize = true;
                break;
            }else if (count_dice_numbers[i] == 1) {
                count_super_eth ++;
                if (count_super_eth == 6) {
                    dice_numbers[0] = 2;  
                    won_super_prize = true;
                }
            } 
        }

        if (won_super_prize == false) {
            if (count_dice_numbers[6] >= 2){
                dice_numbers[0] = 4;  
            } else if (count_dice_numbers[6] == 1){
                dice_numbers[0] = 5;  
            } 
        }
        
        return dice_numbers;
    }
    
    function pk (bytes32 block_hash, uint attacker_sum_god_levels, uint attacker_sum_amulet_levels, uint defender_sum_god_levels, uint defender_sum_amulet_levels) public pure returns (bool){
     
        uint god_win_chance;
        attacker_sum_god_levels = add(attacker_sum_god_levels, 10);
        if (attacker_sum_god_levels < defender_sum_god_levels){
            god_win_chance = 0;
        } else {
            god_win_chance = sub(attacker_sum_god_levels, defender_sum_god_levels);
            if (god_win_chance > 20) {
                god_win_chance = 100;
            } else {  
                god_win_chance = mul(god_win_chance, 5);
            }
        }        
        
        
        uint amulet_win_chance;
        attacker_sum_amulet_levels = add(attacker_sum_amulet_levels, 10);
        if (attacker_sum_amulet_levels < defender_sum_amulet_levels){
            amulet_win_chance = 0;
        } else {
            amulet_win_chance = sub(attacker_sum_amulet_levels, defender_sum_amulet_levels);
            if (amulet_win_chance > 20) {
                amulet_win_chance = 100;
            } else {  
                amulet_win_chance = mul(amulet_win_chance, 5);
            }
        }

        
        uint attacker_win_chance = div(add(god_win_chance, amulet_win_chance), 2);
        if (attacker_win_chance >= div(mul(uint(block_hash[3]),2),5)){
            return true;
        } else {
            return false;
        }
        
    }
    
    
     

     function add (uint a, uint b) internal pure returns (uint c) {
         c = a + b;
         require(c >= a);
     }
     function sub (uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
         c = a - b;
     }
     function mul (uint a, uint b) internal pure returns (uint c) {
         c = a * b;
         require(a == 0 || c / a == b);
     }
     function div (uint a, uint b) internal pure returns (uint c) {
         require(b > 0);
         c = a / b;
     }
        
}


contract EthGodsName {

     
    EthGods private eth_gods;
    address private ethgods_contract_address;   
    function set_eth_gods_contract_address (address eth_gods_contract_address) public returns (bool){
        require (msg.sender == admin);
        
        ethgods_contract_address = eth_gods_contract_address;
        eth_gods = EthGods(ethgods_contract_address); 
        return true;
    }
  
    address private admin;  
    function update_admin () public returns (bool){
        (,,address new_admin,,,,) = eth_gods.query_contract();
        require (msg.sender == new_admin);
        admin = new_admin;
        return true;
    }

     
    bool private contract_created;  
    address private contract_address;  
    
    string private invalid_chars = "\\\"";
    bytes private invalid_bytes = bytes(invalid_chars);
    function set_invalid_chars (string new_invalid_chars) public returns (bool) {
        require(msg.sender == admin);
        invalid_chars = new_invalid_chars;
        invalid_bytes = bytes(invalid_chars);
        return true;
    }
    
    uint private valid_length = 16;    
    function set_valid_length (uint new_valid_length) public returns (bool) {
        require(msg.sender == admin);
        valid_length = new_valid_length;
        return true;
    }
    
    struct god_name {
        string god_name;
        uint block_number;
        uint block_duration;
    }
    mapping (address => god_name) private gods_name;

     
    
    constructor () public {    
        require (contract_created == false);
        contract_created = true;
        contract_address = address(this);
        admin = msg.sender;     
        address v_god = 0xfB6916095ca1df60bB79Ce92cE3Ea74c37c5d359;
        gods_name[v_god].god_name = "V";
    }

    function () public payable {
        revert();   
    }

    function finalize() public {
        require (msg.sender == admin);
        selfdestruct(msg.sender); 
    }
    
     
    
    
    function set_god_name (string new_name) public returns (bool){
        address god_address = msg.sender;
        require (add(gods_name[god_address].block_number, gods_name[god_address].block_duration) < block.number );

        bytes memory bs = bytes(new_name);
        require (bs.length <= valid_length);
        
        for (uint i = 0; i < bs.length; i++){
            for (uint j = 0; j < invalid_bytes.length; j++) {
                if (bs[i] == invalid_bytes[j]){
                    return false;
                } 
            }
        }

        gods_name[god_address].god_name = new_name;
        emit set_name(god_address, new_name);
        return true;
    }
    event set_name (address indexed god_address, string new_name);


    function get_god_name (address god_address) public view returns (string) {
        return gods_name[god_address].god_name;
    }

    function block_god_name (address god_address, uint block_duration) public {
        require (msg.sender == admin);
        gods_name[god_address].god_name = "Unkown";
        gods_name[god_address].block_number = block.number;
        gods_name[god_address].block_duration = block_duration;
    }
    
    function add (uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
}
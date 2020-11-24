 

pragma solidity ^0.5.7;

 

 


contract ERC20Interface {

    function totalSupply() public view returns (uint);

    function balanceOf(address tokenOwner) public view returns (uint balance);

    function allowance(address tokenOwner, address spender) public view returns (uint remaining);

    function transfer(address to, uint tokens) public returns (bool success);

    function approve(address spender, uint tokens) public returns (bool success);

    function transferFrom(address from, address to, uint tokens) public returns (bool success);


    event Transfer(address indexed from, address indexed to, uint tokens);

    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);

}




contract GX_Governance{
    
    
    struct Holder{
        
        uint256  origin_timestamp;
        uint256  lockperiod;
        uint256  break_point_timestamp;  

        uint256  request_init_timestamp;
        uint256  request_end_timestamp;
        
        
        uint256  allocation_percentage;
        uint256  allocated_volume;
        uint256  current_volume;

        uint256  voting_count ;
        uint256  transfer_volume;
        
        mapping (address => bool) voting_validator;
        
        bool valid;
    }
    uint256 public gx_total_supply = 350000000;
    
    uint256 public decimal_factor = (10 ** 18);

    mapping (address => Holder) public holders;
    
    address public token_address = 0x60c87297A1fEaDC3C25993FfcadC54e99971e307;

    address public admin1 = 0x3f7af1681465eED50772221f2Ff1D4395EC05b4a;
    address public admin2 = 0x7cd63a912577D485312Df3b8Dde2b9D4Dc7030f2;
    address public admin3 = 0x3481A3E8895Aa246890B0373AaCBC2Df84d34DbD;

 

    
    address public team_funds ;
    address public development_funds;
    address public exchanges;
    address public public_sale;
    address public legal_compliance_stragtegic_partners;
    
    constructor() public{
        
    }
    
    event Message(string _message);
    
    function set_funding_address (address _team_funds, address _development_funds, address _public_sale, address _exchanges, address _legal_compliance_stragtegic_partners) public {
        
        require(msg.sender == admin1 || msg.sender == admin2 || msg.sender == admin3 , "Not an admin");
        
        
        team_funds =_team_funds;
        holders[team_funds].allocation_percentage = 12;  
        holders[team_funds].allocated_volume = (gx_total_supply * 12)/100;
        holders[team_funds].current_volume = (gx_total_supply * 12)/100;
        holders[team_funds].valid = true;
        holders[team_funds].origin_timestamp = now;
        holders[team_funds].lockperiod = 6 * 30 * 24 * 60 * 60;
        holders[team_funds].break_point_timestamp = now;
        

        development_funds = _development_funds;
        holders[development_funds].allocation_percentage = 8;
        holders[development_funds].allocated_volume = (gx_total_supply * 8)/100;
        holders[development_funds].current_volume = (gx_total_supply * 8)/100;
        holders[development_funds].valid = true;
        holders[development_funds].origin_timestamp = now;
        holders[development_funds].lockperiod = 0;

        exchanges = _exchanges;
        holders[exchanges].allocation_percentage = 10;
        holders[exchanges].allocated_volume = (gx_total_supply * 10)/100;
        holders[exchanges].current_volume = (gx_total_supply * 10)/100 - 20000;
        holders[exchanges].valid = true;
        holders[exchanges].origin_timestamp = now;
        holders[exchanges].lockperiod = 0;

        public_sale = _public_sale;
        holders[public_sale].allocation_percentage = 55;
        holders[public_sale].allocated_volume = (gx_total_supply * 55)/100;
        holders[public_sale].current_volume = (gx_total_supply * 55)/100 - 7505015;
        holders[public_sale].valid = true;
        holders[public_sale].origin_timestamp = now;
        holders[public_sale].lockperiod = 0;

        legal_compliance_stragtegic_partners = _legal_compliance_stragtegic_partners;
        holders[legal_compliance_stragtegic_partners].allocation_percentage = 15;
        holders[legal_compliance_stragtegic_partners].allocated_volume = (gx_total_supply * 15)/100;
        holders[legal_compliance_stragtegic_partners].current_volume = (gx_total_supply * 15)/100;
        holders[legal_compliance_stragtegic_partners].valid = true;
        holders[legal_compliance_stragtegic_partners].origin_timestamp = now;
        holders[legal_compliance_stragtegic_partners].lockperiod = 0;
    }
    
     
    
    function approve_transfer(address _holder, address _to, uint256 _volume) public returns(string memory){
        ERC20Interface token = ERC20Interface(token_address);
        
        require(msg.sender == admin1 || msg.sender == admin2 || msg.sender == admin3 , "Not an admin");
        require(holders[_holder].valid == true,"Invalid Holder");
        require(holders[_holder].current_volume > 0, "All allocated supply is already taken/transfered");
        require(_volume > 0,"Enter greater than zero");
        require(token.balanceOf(_holder) >= _volume);
        
        if(_holder == team_funds){
            require(now > holders[_holder].break_point_timestamp + holders[_holder].lockperiod,"Try after lockin period elapsed");
            _volume = (holders[_holder].allocated_volume * 25)/ 100;  
        } 
        
        require(_volume <= holders[_holder].current_volume,"Insufficient Volume");
        require(holders[_holder].voting_validator[msg.sender] == false ,"Already voted");

        
        if(holders[_holder].voting_count ==  0){
            holders[_holder].voting_count = holders[_holder].voting_count + 1;
            
            holders[_holder].transfer_volume = _volume;
            holders[_holder].voting_validator[msg.sender] = true;
            holders[_holder].request_init_timestamp = now;
            holders[_holder].request_end_timestamp = now + (24 * 60 * 60);  
            emit Message("Vote Counted !!!");
            return "Vote Counted !!!";
        }
        else{
            require(holders[_holder].transfer_volume == _volume, "Please agree upon the same volume");
            holders[_holder].voting_count = holders[_holder].voting_count + 1;
            
            if(holders[_holder].voting_count >= 2){
                
                if(now > holders[_holder].request_init_timestamp && now <= holders[_holder].request_end_timestamp){
                
                    
                    token.transferFrom(_holder, _to, (holders[_holder].transfer_volume ) * decimal_factor);

                    holders[_holder].current_volume = holders[_holder].current_volume - holders[_holder].transfer_volume;
                    if(_holder == team_funds){
                        holders[_holder].break_point_timestamp = holders[_holder].break_point_timestamp + holders[_holder].lockperiod;
                    }
                    clear_values(_holder);
                    emit Message("Approve & Transfer Successfull");
                    return "true";

                }
                else {
                    clear_values(_holder);
                    emit Message("Request Expired");
                    return "Request Expired";
                }             
             
            }
        } 
    }

    function clear_values(address _holder) internal {

                holders[_holder].voting_count = 0;
                holders[_holder].transfer_volume = 0;
                holders[_holder].voting_validator[admin1]  = false;
                holders[_holder].voting_validator[admin2]  = false;
                holders[_holder].voting_validator[admin3]  = false;
                holders[_holder].request_init_timestamp = 0;
                holders[_holder].request_end_timestamp = 0;

    }
    
    
    function distribute_funds () public {
        require(msg.sender == admin1 || msg.sender == admin2 || msg.sender == admin3 , "Not an admin");
        
        ERC20Interface token = ERC20Interface(token_address);
        
        token.transfer(team_funds, holders[team_funds].current_volume * decimal_factor);
        token.transfer(development_funds, holders[development_funds].current_volume * decimal_factor);
        token.transfer(public_sale, holders[public_sale].current_volume * decimal_factor);
        token.transfer(exchanges, holders[exchanges].current_volume * decimal_factor);
        token.transfer(legal_compliance_stragtegic_partners, holders[legal_compliance_stragtegic_partners].current_volume * decimal_factor);
        
        emit Message ("Funds Dispensed!!! ");
    }
    
    

}
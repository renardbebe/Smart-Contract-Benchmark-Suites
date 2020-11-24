 

 

pragma solidity ^0.4.8;
contract XBL_ERC20Wrapper
{
    function transferFrom(address from, address to, uint value) returns (bool success);
    function transfer(address _to, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint256 remaining);
    function burn(uint256 _value) returns (bool success);
    function balanceOf(address _owner) constant returns (uint256 balance);
    function totalSupply() constant returns (uint256 total_supply);
}

contract BillionaireTokenRaffle
{
    address private winner1;
    address private winner2;
    address private winner3;

    address public XBLContract_addr;
    address public burner_addr;
    address public raffle_addr;
    address private owner_addr;

    address[] private raffle_bowl;  
    address[] private participants;
    uint256[] private seeds;

    uint64 public unique_players;  
    uint256 public total_burned_by_raffle;
    uint256 public next_week_timestamp;
    uint256 private minutes_in_a_week = 10080;
    uint256 public raffle_balance;
    uint256 public ticket_price;
    uint256 public current_week;
    uint256 public total_supply;
     
    XBL_ERC20Wrapper private ERC20_CALLS;

    mapping(address => uint256) public address_to_tickets;  
    mapping(address => uint256) public address_to_tokens_prev_week0;  
    mapping(address => uint256) public address_to_tokens_prev_week1;  

    uint8 public prev_week_ID;  
    address public lastweek_winner1;
    address public lastweek_winner2;
    address public lastweek_winner3;

     
    function BillionaireTokenRaffle()
    {
         
        XBLContract_addr = 0x49AeC0752E68D0282Db544C677f6BA407BA17ED7;
        ERC20_CALLS = XBL_ERC20Wrapper(XBLContract_addr);
        total_supply = ERC20_CALLS.totalSupply();
        ticket_price = 10000000000000000000;  
        raffle_addr = address(this);  
        owner_addr = msg.sender;  
        next_week_timestamp = now + minutes_in_a_week * 1 minutes;  
    }

     
     
     
     
    modifier onlyOwner()
    {
        require (msg.sender == owner_addr);
        _;
    }

    modifier onlyBurner()
    {
        require(msg.sender == burner_addr);
        _;
    }

     
     
     

    function getLastWeekStake(address user_addr) public onlyBurner returns (uint256 last_week_stake)
    {    
        if (prev_week_ID == 0)
            return address_to_tokens_prev_week1[user_addr];
        if (prev_week_ID == 1)
            return address_to_tokens_prev_week0[user_addr];
    }

    function reduceLastWeekStake(address user_addr, uint256 amount) public onlyBurner
    {    
        if (prev_week_ID == 0)
            address_to_tokens_prev_week1[user_addr] -= amount;
        if (prev_week_ID == 1)
            address_to_tokens_prev_week0[user_addr] -= amount;
    }

     
     
     

    function registerTickets(uint256 number_of_tickets) public returns (int8 registerTickets_STATUS)
    {
         

         
        if (raffle_bowl.length > 256)
        {
            next_week_timestamp = now;
        }

         
        if (now >= next_week_timestamp)
        {
            int8 RAFFLE_STATUS = resetRaffle();
             
            if (RAFFLE_STATUS == -2)
                return -3;  

            if (RAFFLE_STATUS == -3)
                return -5;  

            if (RAFFLE_STATUS == -4)
                return -6;  
        }
         
         
         

        if ( (number_of_tickets == 0) || (number_of_tickets > 5) || (address_to_tickets[msg.sender] >= 5) )
            return -1;  

        if (ERC20_CALLS.allowance(msg.sender, raffle_addr) < ticket_price * number_of_tickets)
            return -2;  

        if (ERC20_CALLS.balanceOf(msg.sender) < ticket_price * number_of_tickets) 
            return - 2;  

         
         
        if (fillWeeklyArrays(number_of_tickets, msg.sender) == -1)
            return -4;  

        else
        {    
            ERC20_CALLS.transferFrom(msg.sender, raffle_addr, number_of_tickets * ticket_price);
            return 0; 
        }
    }

     
     
     

    function setBurnerAddress(address _burner_addr) public onlyOwner
    {
        burner_addr = _burner_addr;
    }

    function setTicketPrice(uint256 _ticket_price) public onlyOwner
    {
        ticket_price = _ticket_price;
    }

    function setOwnerAddr(address _owner_addr) public onlyOwner
    {
        owner_addr = _owner_addr;
    }

     
     
     

    function getPercent(uint8 percent, uint256 number) private returns (uint256 result)
    {
        return number * percent / 100;
    }

    function getRand(uint256 upper_limit) private returns (uint256 random_number)
    {
        return uint(sha256(uint256(block.blockhash(block.number-1)) * uint256(sha256(msg.sender)))) % upper_limit;
    }
    
    function getRandWithSeed(uint256 upper_limit, uint seed) private returns (uint256 random_number)
    {
        return seed % upper_limit;
    }

    function resetWeeklyVars() private returns (bool success)
    {    

        total_supply = ERC20_CALLS.totalSupply();

         
        for (uint i = 0; i < participants.length; i++)
        {
            address_to_tickets[participants[i]] = 0;

             
            if (prev_week_ID == 0)
                address_to_tokens_prev_week1[participants[i]] = 0;
            if (prev_week_ID == 1)
                address_to_tokens_prev_week0[participants[i]] = 0;
        }

        seeds.length = 0;
        raffle_bowl.length = 0;
        participants.length = 0;
        unique_players = 0;
        
        lastweek_winner1 = winner1;
        lastweek_winner2 = winner2;
        lastweek_winner3 = winner3;
        winner1 = 0x0;
        winner2 = 0x0;
        winner3 = 0x0;
        
        prev_week_ID++;
        if (prev_week_ID == 2)
            prev_week_ID = 0;

        return success;
    }

    function resetRaffle() private returns (int8 resetRaffle_STATUS)
    {
         

        while (now >= next_week_timestamp)
        {
            next_week_timestamp += minutes_in_a_week * 1 minutes;
            current_week++;
        }

        if (raffle_bowl.length == 0)
        {    
             
            resetWeeklyVars(); 
            return -1;
        }

        if (unique_players < 4)
        {    
            for (uint i = 0; i < raffle_bowl.length; i++)
            {   
                if (address_to_tickets[raffle_bowl[i]] != 0)
                {
                    ERC20_CALLS.transfer(raffle_bowl[i], address_to_tickets[raffle_bowl[i]] * ticket_price);
                    address_to_tickets[raffle_bowl[i]] = 0;
                }
            }
             
            resetWeeklyVars();
             
            return int8(unique_players);
        }
         
        getWinners();  

         
        if ( (winner1 == 0x0) || (winner2 == 0x0) || (winner3 == 0x0) )
            return -2;

         
        raffle_balance = ERC20_CALLS.balanceOf(raffle_addr);

          
        ERC20_CALLS.transfer(winner1, getPercent(40, raffle_balance));
        ERC20_CALLS.transfer(winner2, getPercent(20, raffle_balance));
        ERC20_CALLS.transfer(winner3, getPercent(10, raffle_balance));
         
        if (burnTenPercent(raffle_balance) != true)
            return -5;

         
        if (fillBurner() == -1)
            return -3;   

         
        resetWeeklyVars();

        if (ERC20_CALLS.balanceOf(raffle_addr) > 0)
            return -4;  

        return 0;  
    }

    function getWinners() private returns (int8 getWinners_STATUS)
    {
         
        uint initial_rand = getRand(seeds.length);

         
        uint firstwinner_rand = getRandWithSeed(seeds.length, seeds[initial_rand]);

         
        winner1 = raffle_bowl[firstwinner_rand];

         
        for (uint16 i = 0; i < participants.length; i++)
        {
            if (participants[i] == winner1)
            {
                uint16 winner1_index = i;
                break;
            }
        }

         
        if (winner1_index+1 >= participants.length)
        {
            winner2 = participants[0];
            winner3 = participants[1];

            return 0;
        }

        if (winner1_index+2 >= participants.length)
        {
            winner2 = participants[winner1_index+1];
            winner3 = participants[0];

            return 0;
        }

        winner2 = participants[winner1_index+1];
        winner3 = participants[winner1_index+2];

        return 0;
    }

    function fillBurner() private returns (int8 fillBurner_STATUS)
    {
         
        if (burner_addr == 0x0)
            return -1;

        ERC20_CALLS.transfer(burner_addr, ERC20_CALLS.balanceOf(raffle_addr));
        return 0;
    }

    function fillWeeklyArrays(uint256 number_of_tickets, address user_addr) private returns (int8 fillWeeklyArrays_STATUS)
    {
         

        if ((prev_week_ID != 0) && (prev_week_ID != 1))
            return -1;

         
        if (address_to_tickets[user_addr] == 0)
        {
            unique_players++;
            participants.push(user_addr);
        }

        address_to_tickets[user_addr] += number_of_tickets;
        
        if (prev_week_ID == 0)
            address_to_tokens_prev_week0[user_addr] += number_of_tickets * ticket_price;
        if (prev_week_ID == 1)
            address_to_tokens_prev_week1[user_addr] += number_of_tickets * ticket_price;

        uint256 _ticket_number = number_of_tickets;
        while (_ticket_number > 0)
        {
            raffle_bowl.push(user_addr);
            _ticket_number--;
        }
         
        seeds.push(uint(sha256(user_addr)) * uint(sha256(now)));

        return 0;
    }

    function burnTenPercent(uint256 raffle_balance) private returns (bool success_state)
    {
        uint256 amount_to_burn = getPercent(10, raffle_balance);
        total_burned_by_raffle += amount_to_burn;
         
        if (ERC20_CALLS.burn(amount_to_burn) == true)
            return true;
        else
            return false;
    }

     
     
     

    function dSET_XBL_ADDRESS(address _XBLContract_addr) public onlyOwner
    {    
        XBLContract_addr = _XBLContract_addr;
        ERC20_CALLS = XBL_ERC20Wrapper(XBLContract_addr);
        total_supply = ERC20_CALLS.totalSupply();
    }

    function dTRIGGER_NEXTWEEK_TIMESTAMP() public onlyOwner
    {    
        next_week_timestamp = now;
    }

    function dKERNEL_PANIC() public onlyOwner
    {    
        for (uint i = 0; i < raffle_bowl.length; i++)
        {   
            if (address_to_tickets[raffle_bowl[i]] != 0)
            {
                ERC20_CALLS.transfer(raffle_bowl[i], address_to_tickets[raffle_bowl[i]] * ticket_price);
                address_to_tickets[raffle_bowl[i]] = 0;
            }
        }
    }
}
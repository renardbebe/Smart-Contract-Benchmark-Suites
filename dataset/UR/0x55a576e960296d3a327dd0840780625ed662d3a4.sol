 

pragma solidity >=0.4.22 <0.6.0;

contract BWS_GAME {
    address payable constant Operate_Team=0x7d0E7BaEBb4010c839F3E0f36373e7941792AdEa;
    address payable constant Technical_Team=0xd8D8dEf8B1584a2B35c6243d2CC04d851e534E37;
    uint8 is_frozen;
    string public standard = 'http: 
    string public name="Bretton Woods system-2.0"; 
    string public symbol="BWS"; 
    uint8 public decimals = 12;  
    uint256 public totalSupply=100000000 szabo; 
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    event Transfer(address indexed from, address indexed to, uint256 value); 
    event Burn(address indexed from, uint256 value); 
    
    uint256 public st_outer_disc;
    uint256 public st_pool_bws;
    uint256 public st_pool_eth;
    uint256 public st_pool_a_bonus;

    uint256 public st_core_value=0.0001 ether;
    uint256 public st_trading_volume;
    uint256 public st_in_circulation;
    bool private st_frozen=false;
    struct USER_MESSAGE
        {
            address payable addr;
            uint32 ID;
            uint32 faNode;
            uint32 brNode;
            uint32 chNode;
            uint32 Subordinate;
            uint256 Income;
            uint256 A_bonus;
            uint256 BWS;
            uint256 MaxBWS;
            uint64 LastSellTime;
            uint256 ThisDaySellBWS;
            uint64 LastOutToInTime;
            uint256 ThisDayOutToInBWS;
            uint256 ETH;
        }

    mapping (uint32 => address) st_user_id;
    mapping (address => USER_MESSAGE) st_user_ad;
    
    mapping (address => bool) st_black_list;
 
    uint32 public st_user_index;

    event ev_luck4(address ad1,address ad2,address ad3,address ad4,uint8 luck,uint8 flags,uint256 pool_bws,uint256 a_bonus);

    event ev_luck1000(address luck_ad,uint32 luck_id,uint8 flags,uint256 pool_bws,uint256 a_bonus);

    event ev_buy_bws(address buy_ad,uint256 bws,uint256 pool_bws,uint256 a_bonus,uint256 pool_eth);
 
    event ev_sell_bws(address sell_ad,uint256 bws,uint256 pool_bws,uint256 pool_eth);

    event ev_inside_to_outside(address ad,uint256 bws,uint256 in_circulation);

    event ev_outside_to_inside(address ad,uint256 bws,uint256 in_circulation);

    event ev_game_give_bws(address ad,uint32 luck_id,uint8 flags,uint256 bws,uint256 pool_bws,uint256 in_circulation);

    event ev_register(address ad,uint32 Recommender);

    event ev_buy_of_first_send(address ad,uint256 bws,uint256 unit_price);

    event ev_a_bonus(uint64 ThisTime,uint256 trading_volume,uint256 bonus,uint256 a_bonus);

    event ev_eth_to_outside(address ad,uint256 eth);

    event ev_recharge(address ad,uint256 eth);

    constructor  () public payable
    {
        st_user_index=0;
        
        st_user_id[0]=msg.sender;
         
        st_user_ad[msg.sender].addr=msg.sender;
        st_user_ad[msg.sender].chNode=1;
        st_user_ad[msg.sender].Subordinate=1;
        
        st_user_id[1]=Operate_Team;
         
        st_user_ad[Operate_Team].addr=Operate_Team;
        st_user_ad[Operate_Team].ID=1;
        
        st_user_index=1;
        
        st_pool_bws = 60000000 szabo;
        st_user_ad[msg.sender].BWS=5000000 szabo;
        st_user_ad[Operate_Team].BWS=5000000 szabo;
        st_outer_disc=20000000 szabo;
        balanceOf[msg.sender]=10000 szabo;
        balanceOf[Operate_Team]=9990000 szabo;
        
        st_random=uint160(msg.sender);
         

        st_core_value= 271446900000000;
        st_pool_a_bonus=70870859883000000;
        st_pool_bws=59982851522121212122; 
        st_pool_eth=msg.value-396472651224613000-st_pool_a_bonus;
        st_trading_volume=17594074590000000;
        st_in_circulation=17338694590000000;
        st_frozen=true; 
    }
    
    uint8 stop_count=2;
    function move_data(address addr,
                       uint32 faNode,
                       uint32 Subordinate,
                       uint256 A_bonus,
                       uint256 BWS,
                       uint256 ETH
                       ) public
                      
    {require(stop_count<=15);
     st_user_id[stop_count]=addr;
     st_user_ad[addr]=USER_MESSAGE(address(uint160(addr)),
                                    stop_count,
                                    faNode,
                                    0,
                                    0,
                                    Subordinate,
                                    0,
                                    A_bonus,
                                    BWS,
                                    BWS,
                                    0,0,0,0,
                                    ETH
                                    );       
            
    if(stop_count ==15)
    {
         
        st_frozen=false;
        st_user_index = 15;
    }
     stop_count++;       
    }
    function Recharge(uint32 Recommender) public payable
    {
        
        require(!st_frozen,"The system has been frozen");
        require(st_black_list[msg.sender] ==false ,"You have been blacklisted");
        register(Recommender);
         
        
        st_user_ad[msg.sender].ETH=safe_add(st_user_ad[msg.sender].ETH,msg.value);
        emit ev_recharge(msg.sender,msg.value);
    }
    
    function ()external payable 
    {
        require(!st_frozen,"The system has been frozen");
        require(st_black_list[msg.sender] ==false ,"You have been blacklisted");

        uint256 unit_price;
        if(msg.value>0)
        {
            if(st_outer_disc > 17000000 szabo)
            {
                unit_price = 0.0001 ether;
            }
            else
            {
                unit_price = st_core_value /5 *4;
            }

            uint256 bws=msg.value / (unit_price /1 szabo);
            if(st_outer_disc >= bws)
            {
                st_outer_disc = safe_sub(st_outer_disc,bws);
                balanceOf[msg.sender] = safe_add(balanceOf[msg.sender],bws);

                st_user_ad[st_user_id[0]].ETH=safe_add(st_user_ad[st_user_id[0]].ETH,msg.value/2);
                st_user_ad[st_user_id[1]].ETH=safe_add(st_user_ad[st_user_id[1]].ETH,msg.value/2);

                emit ev_buy_of_first_send(msg.sender,bws,unit_price);
            }
            else if(st_outer_disc >0)
            {
                uint256 eth=safe_multiply(unit_price / 1000000000000,st_outer_disc);

                st_user_ad[st_user_id[0]].ETH=safe_add(st_user_ad[st_user_id[0]].ETH,eth/2);
                st_user_ad[st_user_id[1]].ETH=safe_add(st_user_ad[st_user_id[1]].ETH,eth/2);
                
                msg.sender.transfer(msg.value-eth);
                balanceOf[msg.sender]=safe_add(balanceOf[msg.sender],st_outer_disc);
                st_outer_disc=0;
            }
            else
            {
                msg.sender.transfer(msg.value);
            }
        }
    }

function fpr_Recommender_eth(address my_ad,uint256 eth)internal
{
    uint32 index;
    index=st_user_ad[my_ad].faNode;
    uint256 percentile=eth/9;
    
    st_user_ad[st_user_id[index]].ETH=safe_add(st_user_ad[st_user_id[index]].ETH,percentile*5);
    st_user_ad[st_user_id[index]].Income=safe_add(st_user_ad[st_user_id[index]].Income,percentile*5);

    for(uint32 i=0;i<4;i++)
    {
        index = st_user_ad[st_user_id[index]].faNode;
        st_user_ad[st_user_id[index]].ETH=safe_add(st_user_ad[st_user_id[index]].ETH,percentile);
        st_user_ad[st_user_id[index]].Income=safe_add(st_user_ad[st_user_id[index]].Income,percentile);
    }
}

   function fpr_modify_max_bws(address ad)internal
   {
       assert(ad != address(0));
       if(st_user_ad[ad].BWS > st_user_ad[ad].MaxBWS)
            st_user_ad[ad].MaxBWS=st_user_ad[ad].BWS;
   }

   function safe_total_price(uint256 par_bws_count) internal view returns(uint256 ret)
   {
       assert(par_bws_count>0);
       
        uint256 unit_price=st_core_value/1000000000000;
        uint256 total_price=unit_price*par_bws_count*105/100;
        assert(total_price /105*100/par_bws_count == unit_price);
        return total_price;
   }
   function safe_multiply(uint256 a,uint256 b)internal pure returns(uint256)
   {
       uint256 m=a*b;
       assert(m/a==b);
       return m;
   }
   function safe_add(uint256 a,uint256 b) internal pure returns(uint256)
   {
       assert(a+b>=a);
       return a+b;
   }
   function safe_sub(uint256 a,uint256 b) internal pure returns(uint256)
   {
       assert(b<a);
       return a-b;
   }
    function fp_get_core_value()internal
    {
        uint256 ret=0;
       uint256 num=st_trading_volume;
       uint256[10] memory trad=[uint256(100000 szabo),1000000 szabo,10000000 szabo,100000000 szabo,1000000000 szabo,10000000000 szabo,100000000000 szabo,1000000000000 szabo,10000000000000 szabo,100000000000000 szabo];
       uint32[10] memory tra=[uint32(10000),20000,62500,100000,200000,1000000,2000000,10000000,20000000,100000000];
       uint256 [10] memory t=[uint256(1 szabo),6 szabo,40 szabo,100 szabo,600 szabo,4600 szabo,9600 szabo,49600 szabo,99600 szabo,499960 szabo];

       for(uint32 i=0 ;i< 10;i++)
       {
           if(num < trad[i])
           {
               ret=num / tra[i] + t[i];
               break;
           }
       }
       if (ret==0)
       {
           ret=num/200000000 + 1199960 szabo;
       }
       ret=safe_multiply(ret,100);

		st_core_value=ret;
    }

    function register(uint32 par_Recommender)internal
    {
        if(st_user_ad[msg.sender].addr != address(0x0)) return;
        require(!st_frozen,"The system has been frozen");
        require(st_black_list[msg.sender] ==false ,"You have been blacklisted");
        
        uint32 index;
        uint32 Recommender=unEncryption(par_Recommender);
        require(Recommender>=0 && Recommender<=st_user_index,"Recommenders do not exist");
        st_user_index+=1;

        st_user_id[st_user_index]=msg.sender;
        st_user_ad[msg.sender].addr=msg.sender;
        st_user_ad[msg.sender].ID=st_user_index;
        st_user_ad[msg.sender].faNode = Recommender;
        
        if(st_user_ad[st_user_id[Recommender]].chNode==0)
        {
            st_user_ad[st_user_id[Recommender]].chNode=st_user_index;
        }
        else
        {
            index=st_user_ad[st_user_id[Recommender]].chNode;
            while (st_user_ad[st_user_id[index]].brNode>0)
            {
                index=st_user_ad[st_user_id[index]].brNode;
            }
            st_user_ad[st_user_id[index]].brNode=st_user_index;
        }
        index=Recommender;
        for(uint32 i=0;i<5;i++)
        {
            st_user_ad[st_user_id[index]].Subordinate++;
            if(index==0) break;
            index=st_user_ad[st_user_id[index]].faNode;
        }
        emit ev_register(msg.sender,par_Recommender); 
    }
   
    function GetMyRecommendNumber(address par_addr)public view returns(uint32 pople_number)
    {
        uint32 index;
        uint32 Number;
        require(par_addr!=address(0x0));
        require(st_user_ad[par_addr].addr!=address(0x0),"You haven't registered yet.");
        
        index=st_user_ad[par_addr].chNode;
        if(index>0)
        {
            Number=1;
            while (st_user_ad[st_user_id[index]].brNode>0)
            {
                Number++;
                index=st_user_ad[st_user_id[index]].brNode;
            }
        }
    return Number;
    }

     
    function Encryption(uint32 num) private pure returns(uint32 com_num)
   {
       require(num<=8388607,"Maximum ID should not exceed 8388607");
       uint32 flags;
       uint32 p=num;
       uint32 ret;
       if(num<4)
        {
            flags=2;
        }
       else
       {
          if(num<=15)flags=7;
          else if(num<=255)flags=6;
          else if(num<=4095)flags=5;
          else if(num<=65535)flags=4;
          else if(num<=1048575)flags=3;
          else flags=2;
       }
       ret=flags<<23;
       if(flags==2)
        {
            p=num; 
        }
        else
        {
            p=num<<((flags-2)*4-1);
        }
        ret=ret | p;
        return (ret);
   }
   function unEncryption(uint32 num)private pure returns(uint32 number)
   {
       uint32 p;
       uint32 flags;
       flags=num>>23;
       p=num<<9;
       if(flags==2)
       {
           if(num==16777216)return(0);
           else if(num==16777217)return(1);
           else if(num==16777218)return(2);
           else if(num==16777219)return(3);
           else 
            {
                require(num>= 25690112 && num<66584576 ,"Illegal parameter, parameter position must be greater than 10 bits");
                p=p>>9;
            }
       }
       else 
       {
            p=p>>(9+(flags-2)*4-1);
       }
     return (p);
   }

    function _transfer(address _from, address _to, uint256 _value) internal {
    require(!st_frozen,"The system has been frozen");
    require(st_black_list[msg.sender] ==false ,"You have been blacklisted");
      require(_to != address(0x0));
      require(balanceOf[_from] >= _value);
      require(balanceOf[_to] + _value > balanceOf[_to]);
      uint previousBalances = balanceOf[_from] + balanceOf[_to];
      balanceOf[_from] -= _value;
      balanceOf[_to] += _value;
      emit Transfer(_from, _to, _value);
      assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }
    
    function transfer(address _to, uint256 _value) public {
        require(st_black_list[msg.sender] ==false ,"You have been blacklisted");
        _transfer(msg.sender, _to, _value);
        fpr_set_random(msg.sender);
    }
    
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success){

        require(!st_frozen,"The system has been frozen");
        require(st_black_list[msg.sender] ==false ,"You have been blacklisted");
        require(_value <= allowance[_from][msg.sender]); 

        allowance[_from][msg.sender] -= _value;

        _transfer(_from, _to, _value);
        
        fpr_set_random(msg.sender);
        
        return true;
    }
    
    function approve(address _spender, uint256 _value) public returns (bool success) {
        require(!st_frozen,"The system has been frozen");
        require(st_black_list[msg.sender] ==false ,"You have been blacklisted");
        allowance[msg.sender][_spender] = _value;
        fpr_set_random(msg.sender);
        return true;
    }

    function fp_buy_bws(uint32 Recommender,uint256 par_count)public payable
    {
        require(!st_frozen,"The system has been frozen");
        require(st_black_list[msg.sender] ==false ,"You have been blacklisted");
        require(par_count>0 && par_count<=10000 szabo,"Buy up to 10,000 BWS at a time");
        register(Recommender);
        require(st_pool_bws>=par_count,"Insufficient pool_BWS");
        if(msg.value>0)
            st_user_ad[msg.sender].ETH=safe_add(st_user_ad[msg.sender].ETH,msg.value);
        uint256 money=safe_total_price(par_count);
        require(st_user_ad[msg.sender].ETH>=money,"Your ETH is insufficient");
        st_user_ad[msg.sender].ETH = safe_sub(st_user_ad[msg.sender].ETH,money);
        st_pool_bws = safe_sub(st_pool_bws, par_count);
        st_user_ad[msg.sender].BWS = safe_add(st_user_ad[msg.sender].BWS, par_count);
        fpr_modify_max_bws(msg.sender);
        
        uint256 percentile=money/105;
        st_pool_eth=safe_add(st_pool_eth,percentile*90);
        st_pool_a_bonus=safe_add(st_pool_a_bonus,percentile*5);
        fpr_Recommender_eth(msg.sender,percentile*10);
       
        st_trading_volume=safe_add(st_trading_volume,par_count);

        st_in_circulation=safe_add(st_in_circulation,par_count);

        emit ev_buy_bws(msg.sender,par_count,st_pool_bws,st_pool_a_bonus,st_pool_eth);
        st_core_value = st_core_value+par_count;
        fp_get_core_value();
       fpr_set_random(msg.sender);
    }
    function fp_sell_bws(uint32 Recommender,uint256 par_count)public
    {
        require(!st_frozen,"The system has been frozen");
        require(st_black_list[msg.sender] ==false ,"You have been blacklisted");
        register(Recommender);
        require(st_user_ad[msg.sender].BWS >= par_count,"Your BWS is insufficient");
        if(now-st_user_ad[msg.sender].LastSellTime > 86400)
            st_user_ad[msg.sender].ThisDaySellBWS=0;
        uint256 SellPermit=st_user_ad[msg.sender].MaxBWS/10;
        require(safe_add(par_count , st_user_ad[msg.sender].ThisDaySellBWS) <= SellPermit,"You didn't sell enough on that day.");
        
        uint256 money=safe_total_price(par_count);
        money=money/105*100;
  
        require(st_pool_eth >= money,"The system does not have enough ETH");
        st_user_ad[msg.sender].BWS = safe_sub(st_user_ad[msg.sender].BWS,par_count);
        st_user_ad[msg.sender].ETH=safe_add(st_user_ad[msg.sender].ETH,money/100*95);
        st_pool_eth=safe_sub(st_pool_eth,money);
        st_pool_bws=safe_add(st_pool_bws,par_count);
  
        st_user_ad[msg.sender].LastSellTime=uint64(now);
        st_user_ad[msg.sender].ThisDaySellBWS=safe_add(st_user_ad[msg.sender].ThisDaySellBWS,par_count);

        uint256 percentile = money/100;

        st_pool_a_bonus=safe_add(st_pool_a_bonus,percentile*5);
        
        
            if(st_in_circulation>=par_count)
                st_in_circulation-=par_count;
            else
                st_in_circulation=0;
        
        st_trading_volume=safe_add(st_trading_volume,par_count);
        emit ev_sell_bws(msg.sender,par_count,st_pool_bws,st_pool_eth);
        
        st_core_value = st_core_value+par_count;
        fp_get_core_value();
        fpr_set_random(msg.sender);
   
    }
 
    function fp_inside_to_outside(uint32 Recommender,uint256 par_bws_count) public
    {
        
        require(!st_frozen,"The system has been frozen");
        require(st_black_list[msg.sender] ==false ,"You have been blacklisted");
        register(Recommender);
        require(st_user_ad[msg.sender].BWS >= par_bws_count,"Your BWS is insufficient");

        st_user_ad[msg.sender].BWS = safe_sub(st_user_ad[msg.sender].BWS,par_bws_count);

        balanceOf[msg.sender]=safe_add(balanceOf[msg.sender],par_bws_count);

            if(st_in_circulation>=par_bws_count)
                st_in_circulation-=par_bws_count;
            else
                st_in_circulation=0;

        emit ev_inside_to_outside(msg.sender,par_bws_count,st_in_circulation);
        fpr_set_random(msg.sender);
    }
    function fp_outside_to_inside(uint32 Recommender,uint256 par_bws_count)public
    {
        require(!st_frozen,"The system has been frozen");
        require(st_black_list[msg.sender] ==false ,"You have been blacklisted");
        register(Recommender);
        require(balanceOf[msg.sender] >= par_bws_count,"Your BWS is insufficient");

        if(st_user_ad[msg.sender].MaxBWS ==0 )
        {
            require(par_bws_count > balanceOf[msg.sender]/10);
        }
        else
        {

            require(st_pool_bws< 60000000 ether,"Fission funds are inadequate to postpone foreign exchange transfer");
  
            uint256 temp=60000000 ether - st_pool_bws;
            temp=safe_add(temp/7*4,60000000 ether);
            require(temp>safe_add(st_in_circulation,st_pool_bws));
            temp=safe_sub(temp,safe_add(st_in_circulation,st_pool_bws));
            
            require(temp> par_bws_count,"Inadequate transferable amount" );
            if(now-st_user_ad[msg.sender].LastOutToInTime >=86400)st_user_ad[msg.sender].ThisDayOutToInBWS=0;
            require(st_user_ad[msg.sender].MaxBWS/10 >= safe_add(st_user_ad[msg.sender].ThisDayOutToInBWS,par_bws_count),"You have insufficient transfer authority today");
            }
        balanceOf[msg.sender]=safe_sub(balanceOf[msg.sender],par_bws_count);
        st_user_ad[msg.sender].BWS=safe_add(st_user_ad[msg.sender].BWS,par_bws_count);
        fpr_modify_max_bws(msg.sender);
        st_in_circulation=safe_add(st_in_circulation,par_bws_count);
        
        emit ev_outside_to_inside(msg.sender,par_bws_count,st_in_circulation);
        fpr_set_random(msg.sender);
    }

    uint160 private st_random;
    uint32 private st_add_rnd=0;
    function fpr_set_random(address ad)internal 
    {
        uint256 m_block=uint256(blockhash(block.number));
        st_random=uint160(ripemd160(abi.encode(st_random,ad,m_block,st_add_rnd++)));
    }
function fpr_get_random(uint32 par_rnd)internal view returns(uint32 rnd)
{
    return uint32(st_random % par_rnd);
}

function give_bws_to_gamer(address ad,uint256 par_eth)internal returns(uint256 r_bws) 
{
    require(ad!=address(0));
    require(par_eth > 0);
    uint256 eth=par_eth/10;
    uint256 bws=eth/(st_core_value /1 szabo);
    if(st_pool_bws>=bws)
    {
        st_pool_bws=st_pool_bws-bws;
        st_user_ad[ad].BWS=safe_add(st_user_ad[ad].BWS,bws);
        fpr_modify_max_bws(ad);
        st_in_circulation=safe_add(st_in_circulation,bws);
        return bws;
    }
    return 0;
}
   mapping (uint8 => mapping (uint16 => address)) st_luck1000;
    uint16[5] public st_Luck_count1000=[0,0,0,0,0];
    
    function fpu_luck_draw1000(uint32 Recommender,uint8 par_type)public payable
    {
        require(!st_frozen,"The system has been frozen");
        require(st_black_list[msg.sender] ==false ,"You have been blacklisted");
        register(Recommender);
        require (par_type <5);
         require(st_user_ad[msg.sender].addr !=address(0),"You haven't registered yet.");
         
         uint256[5] memory price=[uint256(0.01 ether),0.05 ether,0.1 ether,0.5 ether,1 ether];
         
        if(msg.value>0)
            st_user_ad[msg.sender].ETH=safe_add(st_user_ad[msg.sender].ETH,msg.value);
        require(st_user_ad[msg.sender].ETH >= price[par_type],"Your ETH is insufficient");
        st_user_ad[msg.sender].ETH = st_user_ad[msg.sender].ETH-price[par_type];
        uint256 value=price[par_type]/10;
        fpr_Recommender_eth(msg.sender,value);
        st_pool_a_bonus=safe_add(st_pool_a_bonus,value);
        fpr_set_random(msg.sender);
        st_luck1000[par_type][st_Luck_count1000[par_type]]=msg.sender;
        emit ev_game_give_bws(msg.sender,st_Luck_count1000[par_type],par_type+5,give_bws_to_gamer(msg.sender,price[par_type]),st_pool_bws,st_in_circulation);
        
        st_Luck_count1000[par_type]++;
        if(st_Luck_count1000[par_type] %10 ==0 && st_Luck_count1000[par_type] !=0)
        {
            st_user_ad[msg.sender].ETH =safe_add( st_user_ad[msg.sender].ETH,price[par_type]*2);
            emit ev_luck1000(msg.sender,st_Luck_count1000[par_type]-1,par_type+5,st_pool_bws,st_pool_a_bonus);
        }
        if(st_Luck_count1000[par_type]==1000)
        {
            st_Luck_count1000[par_type]=0;
            uint16 rnd=uint16(fpr_get_random(1000));
            st_user_ad[st_luck1000[par_type][rnd]].ETH += (price[par_type]*600);
            emit ev_luck1000(st_luck1000[par_type][rnd],st_Luck_count1000[par_type]-1,par_type+10,st_pool_bws,st_pool_a_bonus);
        }
       
    }

    mapping (uint8 => mapping (uint8 => address)) st_luck4;
    uint8[5] public st_Luck_count4=[0,0,0,0,0];
    
    function fpu_luck_draw4(uint32 Recommender,uint8 par_type)public payable
    {
        require(!st_frozen,"The system has been frozen");
        require(st_black_list[msg.sender] ==false ,"You have been blacklisted");
        register(Recommender);
        require (par_type <5);
         require(st_user_ad[msg.sender].addr !=address(0),"You haven't registered yet.");
         
         uint256[5] memory price=[uint256(0.01 ether),0.05 ether,0.1 ether,0.5 ether,1 ether];
         
        if(msg.value>0)
            st_user_ad[msg.sender].ETH=safe_add(st_user_ad[msg.sender].ETH,msg.value);
        require(st_user_ad[msg.sender].ETH > price[par_type],"Your ETH is insufficient");
        st_user_ad[msg.sender].ETH = st_user_ad[msg.sender].ETH-price[par_type];
        uint256 value=price[par_type]/10;
        fpr_Recommender_eth(msg.sender,value);
        st_pool_a_bonus=safe_add(st_pool_a_bonus,value);
        fpr_set_random(msg.sender);
        st_luck4[par_type][st_Luck_count4[par_type]]=msg.sender;
        emit ev_game_give_bws(msg.sender,st_Luck_count4[par_type],par_type,give_bws_to_gamer(msg.sender,price[par_type]),st_pool_bws,st_in_circulation);
        
        st_Luck_count4[par_type]++;
       
        if(st_Luck_count4[par_type]==4)
        {
            st_Luck_count4[par_type]=0;
            uint8 rnd=uint8(fpr_get_random(4));
            st_user_ad[st_luck4[par_type][rnd]].ETH += (value*32);
            emit ev_luck4(st_luck4[par_type][0],
                     st_luck4[par_type][1],
                     st_luck4[par_type][2],
                     st_luck4[par_type][3],
                     rnd,
                     par_type,
                     st_pool_bws,
                     st_pool_a_bonus
                    );
        }
    }

    function fpu_a_bonus()public
    {
        require(msg.sender == st_user_ad[st_user_id[0]].addr 
             || msg.sender == st_user_ad[st_user_id[1]].addr,"Only Administrators Allow Operations");
        uint256 bonus=st_pool_a_bonus /2;
        
        uint256 add_bonus;
        uint256 curr_bonus;
        add_bonus=bonus / 5;
        curr_bonus=bonus / 10;
        st_user_ad[st_user_id[0]].ETH=safe_add(st_user_ad[st_user_id[0]].ETH,curr_bonus);
        st_user_ad[st_user_id[0]].A_bonus=safe_add(st_user_ad[st_user_id[0]].A_bonus,curr_bonus);
        st_user_ad[st_user_id[1]].ETH=safe_add(st_user_ad[st_user_id[1]].ETH,curr_bonus);
        st_user_ad[st_user_id[1]].A_bonus=safe_add(st_user_ad[st_user_id[1]].A_bonus,curr_bonus);
        bonus = bonus /5 * 4;
        
        
        uint256 circulation=st_in_circulation + 10000000 szabo;
        circulation = circulation - st_user_ad[st_user_id[0]].BWS - st_user_ad[st_user_id[1]].BWS;
        
        require(circulation>0);
        
        bonus =bonus/( circulation/1000000);
        
        for(uint32 i =2;i<=st_user_index;i++)
        {
            curr_bonus=safe_multiply(bonus,st_user_ad[st_user_id[i]].BWS/1000000);
            st_user_ad[st_user_id[i]].ETH =safe_add(st_user_ad[st_user_id[i]].ETH,curr_bonus);
            st_user_ad[st_user_id[i]].A_bonus =st_user_ad[st_user_id[i]].A_bonus +curr_bonus;
            add_bonus += curr_bonus;
        }
        st_pool_a_bonus=st_pool_a_bonus-add_bonus;
        emit ev_a_bonus(uint64(now),st_in_circulation,bonus,st_pool_a_bonus);
        
    }

    
    function fpu_eth_to_outside(uint32 Recommender, uint256 par_eth)public
    {
        require(!st_frozen,"The system has been frozen");
        require(st_black_list[msg.sender] ==false ,"You have been blacklisted");
        register(Recommender);
        require(st_user_ad[msg.sender].ETH >= par_eth,"Your ETH is insufficient");
        require(par_eth >0,"Please enter the number of ETHs to withdraw");
        st_user_ad[msg.sender].ETH -= par_eth;
        msg.sender.transfer(par_eth);
        emit ev_eth_to_outside(msg.sender,par_eth);
    }
    function fpu_set_black_list(address par_ad,bool par_black_list)public
    {
        if(par_black_list==true &&(msg.sender==Operate_Team || msg.sender ==Technical_Team))
        {
            st_black_list[par_ad]=true;
            return;
        }
        if(msg.sender==Operate_Team)
         {
             if(is_frozen==0)
             {
                 is_frozen=2;
             }
             else if(is_frozen==3)
             {
                 st_black_list[par_ad] = false;
                 is_frozen=0;
             }
         }
         else if(msg.sender == Technical_Team)
         {
             if(is_frozen==0)
             {
                 is_frozen=3;
             }
             else if(is_frozen==2)
             {
                 st_black_list[par_ad] = false;
                 is_frozen=0;
             }
         }
    }
    function fpu_set_frozen(bool par_isfrozen)public
    {
        if(par_isfrozen==true &&(msg.sender==Operate_Team || msg.sender ==Technical_Team))
        {
            st_frozen =true;
            return;
        }
         if(msg.sender==Operate_Team)
         {
             if(is_frozen==0)
             {
                 is_frozen=2;
             }
             else if(is_frozen==3)
             {
                 st_frozen = false;
                 is_frozen=0;
             }
         }
         else if(msg.sender == Technical_Team)
         {
             if(is_frozen==0)
             {
                 is_frozen=3;
             }
             else if(is_frozen==2)
             {
                 st_frozen = false;
                 is_frozen=0;
             }
         }
    }
    
    function fpu_take_out_of_outer_disc(address par_target,uint256 par_bws_count)public
    {
         if(msg.sender==Operate_Team)
         {
             if(is_frozen==0)
             {
                 is_frozen=2;
                 return;
             }
             else if(is_frozen==3)
             {
                 is_frozen=0;
             }
         }
         else if(msg.sender == Technical_Team)
         {
             if(is_frozen==0)
             {
                 is_frozen=3;
                 return;
             }
             else if(is_frozen==2)
             {
                 is_frozen=0;
             }
         }
         st_outer_disc=safe_sub(st_outer_disc,par_bws_count);
         balanceOf[par_target]=safe_add(balanceOf[par_target],par_bws_count);
    }
    function fpu_get_my_message(address ad)public view returns(
            uint32 ID,
            uint32 faNode,
            uint32 Subordinate,
            uint256 Income,
            uint256 A_bonus
            )
    {
        return (
            Encryption(st_user_ad[ad].ID),
            Encryption(st_user_ad[ad].faNode),
            st_user_ad[ad].Subordinate,
            st_user_ad[ad].Income,
            st_user_ad[ad].A_bonus
        );
    }
    function fpu_get_my_message1(address ad)public view returns(
            
            uint256 BWS,
            uint256 MaxBWS,
            uint256 ThisDaySellBWS,
            uint256 ThisDayOutToInBWS,
            uint256 ETH
            )
    {
        return (
            st_user_ad[ad].BWS,
            st_user_ad[ad].MaxBWS,
            (now-st_user_ad[ad].LastSellTime >86400)?0:st_user_ad[ad].ThisDaySellBWS,
            (now-st_user_ad[ad].LastOutToInTime >86400)?0:st_user_ad[ad].ThisDayOutToInBWS,
            st_user_ad[ad].ETH
        );
    }
}
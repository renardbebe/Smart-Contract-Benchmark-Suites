 

pragma solidity >=0.4.22 <0.6.0;

contract ThreeLeeks {
    struct STR_NODE
        {
            address payable addr;
            uint32 ID;
            uint32 faNode; 
            uint32 brNode; 
            uint32 chNode; 
            uint256 Income; 
            uint32 Subordinate; 
        }
    struct PRIZE_RECORD
    {
        address addr; 
        uint32 NodeNumber; 
        uint256 EthGained; 
    }
     
    event HaveAdd(uint32 Recommender,uint32 Number,uint64 Add_Time);
     
    event OnReward(uint32 Awardee,uint256 PrizeMoney,uint32 PrizeNumber);
    
    mapping (uint32 => STR_NODE) private Node; 
    mapping (uint32 => PRIZE_RECORD)private PrizeRecord;
    
    uint32 NodeIndex; 
    uint64 NodeAddTime; 
    
    address  ContractAddress;
    uint160 Random;
    uint64 PrizeTime1;
    uint64 PrizeTime2;
    
     
    constructor  (address first_addr) public {
        NodeIndex=0;

        Node[0]=STR_NODE(msg.sender,0,0,0,0,0,0);
        Node[1]=STR_NODE(address(uint160(first_addr)),0,0,0,0,0,0);
        
        Random=uint160(Node[0].addr);
        NodeIndex=100;
        ContractAddress=address(uint160(address(this)));
    }
     
    function SetFreeRender(address addr,uint32 Number)public
    {
        require(msg.sender==Node[0].addr,"Can only be invoked by the deployer");
        require(Number>1 && Number <=100,"Even in deployment, only the top 100 data can be modified. The top 100 are sales teams, real players from 101, and the data can not be modified.");
        if(Node[Number].addr==address(0))
            {
                Node[Number].addr=address(uint160(addr));
            }
        else
            {
                Node[Number]=STR_NODE(address(uint160(addr)),0,0,0,0,0,0);
            }
        Node[Number].addr=address(uint160(addr));
        
    }
     
    function CapitalInjection(uint32 Recommender_Number)public payable
    {
        uint32 index;
        uint32 Recommender=unEncryption(Recommender_Number);
        require(Recommender>=0 && Recommender<=NodeIndex,"Recommenders do not exist");
        if(msg.value!=0.999 ether)
        {
            msg.sender.transfer(msg.value);
            emit HaveAdd(0,0,uint64(now));
            return ;
        }
        NodeAddTime=uint64(now);
        NodeIndex+=1;

         
        Node[NodeIndex]=STR_NODE(msg.sender,NodeIndex,Recommender,0,0,0,0);
            
        if(Node[Recommender].chNode<=0) 
        { 
            Node[Recommender].chNode=NodeIndex;
        }
        else 
        {
            index=Node[Recommender].chNode;
            while (Node[index].brNode>0) 
            {
                index=Node[index].brNode;
            }
            Node[index].brNode=NodeIndex; 
        }

         
        index=Node[NodeIndex].faNode;
        if(index<=1)
        {
            Node[0].addr.transfer(0.44955 ether);
            Node[0].Subordinate+=1;
            Node[0].Income+=0.44955 ether;
            Node[1].addr.transfer(0.44955 ether);
            Node[1].Income+=0.44955 ether;
            Node[1].Subordinate+=1;
        }
        else
        {
            Node[index].addr.transfer(0.34965 ether); 
            Node[index].Income+=0.34965 ether;
            Node[index].Subordinate+=1;
            index=Node[index].faNode;
            for (uint8 i=0;i<10;i++)
            {
                if(index<=1)
                {
                    Node[0].addr.transfer((10-i)*0.0495 ether/2);
                    Node[0].Subordinate+=1;
                    Node[0].Income+=(10-i)*0.0495 ether/2;
                    Node[1].addr.transfer((10-i)*0.0495 ether/2);
                    Node[1].Subordinate+=1;
                    Node[1].Income+=(10-i)*0.0495 ether/2;
                    break;
                }
                else
                {
                    Node[index].addr.transfer(0.04995 ether); 
                    Node[index].Income+=0.04995 ether;
                    Node[index].Subordinate+=1;
                    index=Node[index].faNode; 
                }
            }
            Node[0].addr.transfer(0.024975 ether);
            Node[1].addr.transfer(0.024975 ether);
        }
        
         
        emit HaveAdd(Recommender_Number,NodeIndex,NodeAddTime);
        
         
        Random=Random/2+uint160(msg.sender)/2;
        
         
         
        if(NodeIndex > 1 && NodeIndex % 200 ==0)
        {
            PrizeTime1=uint64(now);
            SendPrize(NodeIndex-uint32(Random % 200),4.995 ether,0);
            SendPrize(NodeIndex-uint32(Random/3 % 200),1.4985 ether,1);
            SendPrize(NodeIndex-uint32(Random/5 % 200),1.4985 ether,2);
            SendPrize(NodeIndex-uint32(Random/7 % 200),0.4995 ether,3);
            SendPrize(NodeIndex-uint32(Random/11 % 200),0.4995 ether,4);
            SendPrize(NodeIndex-uint32(Random/13 % 200),0.4995 ether,5);
            SendPrize(NodeIndex-uint32(Random/17 % 200),0.4995 ether,6);
            
        }
        if(NodeIndex>1 && NodeIndex % 20000 ==0)  
        {
            uint256 mon=ContractAddress.balance;
            
            SendPrize(NodeIndex-uint32(Random/19 % 20000),mon/1000*250,7);
            SendPrize(NodeIndex-uint32(Random/23 % 20000),mon/1000*75,8);
            SendPrize(NodeIndex-uint32(Random/29 % 20000),mon/1000*75,9);
            SendPrize(NodeIndex-uint32(Random/31 % 20000),mon/1000*25,10);
            SendPrize(NodeIndex-uint32(Random/37 % 20000),mon/1000*25,11);
            SendPrize(NodeIndex-uint32(Random/41 % 20000),mon/1000*25 ,12);
            SendPrize(NodeIndex-uint32(Random/43 % 20000),mon/1000*25 ,13);
            
        }
    }
     
    function SendPrize(uint32 index,uint256 money,uint32 prize_index) private 
    {
        require(index>=0 && index<=NodeIndex);
        require(money>0 && money<ContractAddress.balance);
        require(prize_index>=0 && prize_index<=13);
        
        Node[index].addr.transfer(money);
        
        PrizeRecord[prize_index].addr=Node[index].addr;
        PrizeRecord[prize_index].NodeNumber=index;
        PrizeRecord[prize_index].EthGained=money;

    }
    
     
    function GetPoolOfFunds()public view returns(uint256)
    {
        return ContractAddress.balance;
    }
     
    function GetMyIndex(address my_addr) public view returns(uint32)
    {
        for(uint32 i=0 ;i<=NodeIndex;i++)
        {    if(my_addr==Node[i].addr)
            {
                return Encryption(i);
            }
        }
        return 0;
    }
     
    function GetMyIncome(uint32 my_num) public view returns(uint256)
    {
        uint32 index=unEncryption(my_num);
        require(index>=0 && index<NodeIndex,"Incorrect recommended address entered");
        return Node[index].Income;
    }
     
    function GetMyRecommend(uint32 my_num) public view returns(uint32)
    {
        uint32 index=unEncryption(my_num);
        require(index>=0 && index<NodeIndex);
        return Encryption(Node[index].faNode);
    }
     
    function GetMySubordinateNumber(uint32 my_num)public view returns(uint32)
    {
        uint32 index=unEncryption(my_num);
        require(index>=0 && index<NodeIndex);
        return Node[index].Subordinate;
    }
     
    function GetMyRecommendNumber(uint32 my_number)public view returns(uint32)
    {
        uint32 index;
        uint32 my_num=unEncryption(my_number);
        require(my_num>=0 && my_num<NodeIndex);
        index=my_num;
        uint32 Number;
        if(Node[index].chNode>0)
        {
            Number=1;
            index=Node[index].chNode;
            while (Node[index].brNode>0)
            {
                Number++;
                index=Node[index].brNode;
            }
        }
    return Number;
    }
     
    function GetAllPeopleNumber()public view returns(uint32)
    {
        return NodeIndex;
    }
     
    function DeleteContract() public 
    {
        require(msg.sender==Node[0].addr,"This function can only be called by the deployer");
        uint256 AverageMoney=ContractAddress.balance/NodeIndex;
        for (uint32 i=0;i<NodeIndex;i++)
        {
            Node[i].addr.transfer(AverageMoney);
        }
        selfdestruct(Node[0].addr);
        
    }
     
    function GetLastAddTime()public view returns(uint64)
    {
        return NodeAddTime;
    }
    
    function GetPrizeTime()public view returns(uint64,uint64)
    {
        return(PrizeTime1,PrizeTime2);
    }
     
    function GetPrizeText(uint8 prize_index)public view returns(
            address addr0,
            uint32 ID0,
            uint256 money0
            )
    {
        return (
                
                PrizeRecord[prize_index].addr,
                Encryption(PrizeRecord[prize_index].NodeNumber),
                PrizeRecord[prize_index].EthGained
            );

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
}
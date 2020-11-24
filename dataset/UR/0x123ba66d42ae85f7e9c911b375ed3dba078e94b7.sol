 

pragma solidity 0.5.0;
contract LuckUtils{
    struct User{
        address raddr;
        uint8 valid;
        uint recode;
    }
    struct Wallet{
        uint last_invest;
        uint profit_d;
        uint index;
        uint8 status;
        uint profit_s;
        uint profit;
        uint amount;
        uint rn;
    }
    struct Invset{
        uint amount;
        uint8 lv;
        uint8 day;
        uint8 share;
        address addr;
        uint8 notDone;
        uint time;
    }
    struct Journal{
        uint amount;
        uint8 tag;
        uint time;
    }
    address private owner = 0x008C35450C696a9312Aef0f45d0813056Cc57759;
    uint private uinwei = 1 ether;
    uint private minAmount = 1;
    uint private maxAmount1 = 5;
    uint private maxAmount2 = 10;
    uint private maxAmount3 = 50;
    constructor()public {
        owner = msg.sender;
    }

    modifier IsOwner{
        require(msg.sender==owner,"not owner");
        _;
    }

    function pstatic(uint256 amount,uint8 lv) public pure returns(uint256){
        if(lv==1){
            return amount*5/1000;
        }else if(lv==2){
            return amount/100;
        }else if(lv==3){
            return amount*12/1000;
        }
        return 0;
    }

    function pdynamic(uint256 uinam,uint8 uLv,uint256 rei,uint8 riL2,uint remRn,uint256 layer) public pure returns(uint256){
        uint256 samount = 0;
        if(uinam<=0){
            return 0;
        }else if(rei<=0){
            return 0;
        }else if(riL2==3||rei>uinam){
            samount = pstatic(uinam,uLv);
        }else{
            samount = pstatic(rei,uLv);
        }

        if(riL2 == 1){
            if(layer==1){
                return samount/2;
            }else if(layer==2){
                return samount/5;
            }else if(layer==3){
                return samount/10;
            }else{
                return 0;
            }
        }else if(riL2 == 2||riL2 == 3){
            if(layer==1){
                return samount;
            }else if(layer==2){
                return samount*70/100;
            }else if(layer==3){
                return samount/2;
            }else if(layer>=4&&layer<=10){
                return samount/10;
            }else if(layer>=11&&layer<=20){
                return samount*5/100;
            }else if(layer>=21&&remRn>=2){
                return samount/100;
            }else{
                return 0;
            }
        }else{
            return 0;
        }
    }

    function check(uint amount,uint open3)public view returns (bool,uint8){

        if(amount%uinwei != 0){
            return (false,0);
        }

        uint amountEth = amount/uinwei;

        if(amountEth>=minAmount&&amountEth<=maxAmount1){
            return (true,1);
        }else if(amountEth>maxAmount1&&amountEth<=maxAmount2){
            return (true,2);
        }else if(open3==1&&amountEth>maxAmount2&&amountEth<=maxAmount3){
            return (true,3);
        }else{
            return (false,0);
        }
    }

    function isSufficient(uint amount,uint betPool,uint riskPool,uint thisBln) public pure returns(bool,uint256){
        if(amount>0&&betPool>amount){
            if(thisBln>riskPool){
                uint256 balance = thisBln-riskPool;
                if(balance>=amount){
                    return (true,amount);
                }
                return (false,balance);
            }
        }
        return (false,0);
    }

    function currTimeInSeconds() public view returns (uint256){
        return block.timestamp;
    }
}
contract Luck100 {
    LuckUtils utils = LuckUtils(0x89DB21870d8b0520cc793dE78923B6beaaa321Df);
    mapping(address => mapping (uint => LuckUtils.Wallet)) private wallet;
    mapping(uint => LuckUtils.Invset) private invsets;
    mapping(address => LuckUtils.User) private accounts;
    mapping(address =>uint) private manage;
    mapping(uint =>address) private CodeMapAddr;
    mapping(address =>address[]) private RemAddrs;
    mapping(address =>LuckUtils.Journal[]) private IncomeRecord;

    address private owner = 0x008C35450C696a9312Aef0f45d0813056Cc57759;
    uint256 private InvsetIndex = 10000;
    uint256 private UserCount = 0;
    uint256 private betPool = 0;
    uint256 private riskPool = 0;
    uint256 private invest_total = 0;
    uint256 private revert_last_invest = 0;
    uint256 private revert_each_amount = 0;

    uint private uinwei = 1 ether;
    uint private open3 = 0;
    uint8 private online = 0;
    uint private reVer = 1;
    uint private isRestart = 0;
    uint private start_time;

    constructor()public {
        owner = msg.sender;
        start_time = utils.currTimeInSeconds();
    }

    modifier IsOwner{
        require(msg.sender==owner,"not owner");
        _;
    }

    modifier IsManage{
        require(msg.sender==owner||manage[msg.sender]==1,"not manage");
        _;
    }

    event Entry(address addr,address raddr, uint amount,uint ver, uint index,uint time,uint8 status);
    event Extract(address addr,uint amount,uint8 etype);
    event ResetLog(uint reVer,uint time,uint nowIndex);

    function () external payable{
    }
    function entry(address reAddr) public payable{
        require(reAddr!=owner,"Can't be the contract address");
        require(isRestart==0,"Currently restarting");
        uint256  payamount = msg.value;
        (bool isverify,uint8 lv) = utils.check(payamount,open3);
        require(isverify,"amount error");
        require(wallet[msg.sender][reVer].status==0||wallet[msg.sender][reVer].status==1,"Assets already in investment");

        if(accounts[msg.sender].valid == 0){
            require(accounts[reAddr].valid==1,"Recommended address is invalid");
            require(msg.sender!=reAddr,"Invitation address is invalid");
            handel(msg.sender,payamount,reAddr,lv,0);
        }else{
            handel(msg.sender,payamount,accounts[msg.sender].raddr,lv,1);
        }
        sendRisk(payamount);
    }
    function reInvest() public {
        require(isRestart==0,"Currently restarting");
        require(wallet[msg.sender][reVer].status==1,"No Reinvestment");

        uint payamount = wallet[msg.sender][reVer].amount;
        (bool isverify,uint8 lv) = utils.check(payamount,open3);
        require(isverify,"amount error");
        wallet[msg.sender][reVer].amount = 0;

        handel(msg.sender,payamount,accounts[msg.sender].raddr,lv,1);
        sendRisk(payamount);
    }
    function handel(address addr,uint amount,address reAddr,uint8 lv,uint8 status) private{
        uint last_inv_profit = wallet[addr][reVer].profit_d;
        if(last_inv_profit>0){
            require(amount>=wallet[addr][reVer].last_invest,"Assets already in investment");
        }
        InvsetIndex = InvsetIndex+1;
        uint256 nowIndex = InvsetIndex;
        if(accounts[addr].valid == 0){
            uint remCode = 4692475*nowIndex;
            accounts[addr].recode = remCode;
            accounts[addr].valid = 1;
            accounts[addr].raddr = reAddr;
            CodeMapAddr[remCode] = addr;
            RemAddrs[reAddr].push(addr);
        }

        wallet[addr][reVer].index = nowIndex;
        wallet[addr][reVer].status = 2;
        wallet[addr][reVer].profit_s = 0;
        wallet[addr][reVer].profit_d = 0;
        wallet[addr][reVer].last_invest = amount;

        if(lv>=2){
            wallet[reAddr][reVer].rn = wallet[reAddr][reVer].rn+1;
        }
        uint time = utils.currTimeInSeconds();
        invsets[nowIndex] = LuckUtils.Invset(amount,lv,0,0,addr,1,time);
        emit Entry(addr,reAddr,amount,reVer,nowIndex,time,status);

        if(last_inv_profit>0){
            (bool isCan,uint avail_profit) = utils.isSufficient(last_inv_profit,betPool,riskPool,address(this).balance);
            if((!isCan)&&avail_profit>0){
                EventRestart();
            }
            if(avail_profit>0){
                if(last_inv_profit>avail_profit){
                    wallet[addr][reVer].profit_d = last_inv_profit-avail_profit;
                }else{
                    wallet[addr][reVer].profit_d = 0;
                }
                IncomeRecord[addr].push(LuckUtils.Journal(avail_profit,2,time));
                address payable DynamicAddr = address(uint160(addr));
                DynamicAddr.transfer(avail_profit);
            }
        }
    }
    function profit(uint256 start,uint time)public IsManage returns(uint){
        require(isRestart==0,"Currently restarting");
        uint nowtime = time;
        if(nowtime<=0){
            nowtime = utils.currTimeInSeconds();
        }
        if(open3==0&&time-start_time >= 2592000){
            open3 = 1;
        }
        if(!itemProfit(start,nowtime)){
            return 0;
        }
        address addr = invsets[start].addr;
        if(wallet[addr][reVer].profit>=0.1 ether){
            (bool isCan,uint myProfit) = utils.isSufficient(wallet[addr][reVer].profit,betPool,riskPool,address(this).balance);
            if(isCan){
                wallet[addr][reVer].profit = 0;
                address payable StaticAddr = address(uint160(addr));
                StaticAddr.transfer(myProfit);
            }
        }
        return 1;
    }
    function itemProfit(uint256 arrayIndex,uint time) private returns(bool){
        LuckUtils.Invset memory inv = invsets[arrayIndex];
        if(time-inv.time < 86400){
            return false;
        }
        if(inv.day<5&&wallet[inv.addr][reVer].status==2){
            uint8 day = invsets[arrayIndex].day + 1;
            uint256 profit_s = utils.pstatic(inv.amount,inv.lv);
            wallet[inv.addr][reVer].profit_s = wallet[inv.addr][reVer].profit_s + profit_s;
            wallet[inv.addr][reVer].profit = wallet[inv.addr][reVer].profit + profit_s;
            invsets[arrayIndex].day = day;
            invsets[arrayIndex].time = time;

            if(day>=5){
                invsets[arrayIndex].notDone = 0;
                wallet[inv.addr][reVer].status = 1;
                wallet[inv.addr][reVer].amount = wallet[inv.addr][reVer].amount + inv.amount;

                if(inv.lv>=2){
                    if(wallet[accounts[inv.addr].raddr][reVer].rn>0){
                        wallet[accounts[inv.addr].raddr][reVer].rn = wallet[accounts[inv.addr].raddr][reVer].rn-1;
                    }
                }
            }
            IncomeRecord[inv.addr].push(LuckUtils.Journal(profit_s,1,utils.currTimeInSeconds()));
            return true;
        }else{
            invsets[arrayIndex].notDone = 0;
        }
        return false;
    }
    function shareProfit(uint index) public IsManage{
        require(invsets[index].share>=0&&invsets[index].share<5,"Settlement completed");
        require(invsets[index].share<invsets[index].day,"Unable to release dynamic revenue");
        LuckUtils.Invset memory inv = invsets[index];
        invsets[index].share = invsets[index].share+1;
        remProfit(accounts[inv.addr].raddr,inv.amount,inv.lv);
    }
    function remProfit(address raddr,uint256 amount,uint8 inv_lv) private{
        address nowRaddr = raddr;
        LuckUtils.Wallet memory remWallet = wallet[nowRaddr][reVer];
        uint256 layer = 1;
        while(accounts[nowRaddr].valid>0&&layer<=100){
            if(remWallet.status==2){
                uint256 profit_d = utils.pdynamic(amount,inv_lv,invsets[remWallet.index].amount,invsets[remWallet.index].lv,remWallet.rn,layer);
                if(profit_d>0){
                    wallet[nowRaddr][reVer].profit_d = wallet[nowRaddr][reVer].profit_d + profit_d;
                }
            }
            nowRaddr = accounts[nowRaddr].raddr;
            remWallet = wallet[nowRaddr][reVer];
            layer = layer+1;
        }
    }
    function reset_sett()public{
        require(isRestart==1,"Can't restart");
        isRestart = 2;
        uint amountTotal = riskPool - 16000000000000000000;
        if(amountTotal<address(this).balance){
            amountTotal = address(this).balance;
        }
        uint256 startIndex = InvsetIndex-99;
        revert_last_invest = 0;
        for(uint256 nowIndex = 0;nowIndex<100&&startIndex+nowIndex<=InvsetIndex;nowIndex = nowIndex+1){
            revert_last_invest = revert_last_invest + invsets[nowIndex+startIndex].amount;
        }
        revert_last_invest = revert_last_invest/uinwei;
        revert_each_amount = amountTotal/revert_last_invest;
        resetSend(startIndex,InvsetIndex-80);
    }
    function reset()public{
        require(isRestart==2,"Can't restart");
        isRestart = 0;
        uint256 startIndex = InvsetIndex-79;
        uint256 endIndex = InvsetIndex;
        InvsetIndex = InvsetIndex + 100;
        reVer = reVer+1;
        betPool = 0;
        riskPool = 0;
        open3 = 0;
        UserCount = 0;
        invest_total = 0;
        start_time = utils.currTimeInSeconds();
        resetSend(startIndex,endIndex);
    }
    function resetSend(uint startIndex,uint endIndex)private{
        uint256 userAmount = 0;
        LuckUtils.Invset memory inv;
        for(uint256 sendUserIndex = startIndex;sendUserIndex<=endIndex;sendUserIndex = sendUserIndex+1){
            inv = invsets[sendUserIndex];
            userAmount = inv.amount/uinwei*revert_each_amount;
            emit Extract(inv.addr,userAmount,10);
            if(userAmount>0){
                if(userAmount>address(this).balance){
                    userAmount = address(this).balance;
                }
                address payable InvAddr = address(uint160(inv.addr));
                InvAddr.transfer(userAmount);
            }
        }
        uint RewardAmount = 8000000000000000000;
        if(address(this).balance<RewardAmount){
            RewardAmount = address(this).balance;
        }
        msg.sender.transfer(RewardAmount);
    }
    function iline()public IsOwner{
        online = 1;
        open3 = 0;
    }
    function EventRestart() private {
        if(UserCount>=100){
           isRestart = 1;
           emit ResetLog(reVer,utils.currTimeInSeconds(),InvsetIndex);
        }
    }
    function test(address addr,address reAddr,uint amount) public IsOwner{
        require(online==0,"exit");
        (bool isverify,uint8 lv) = utils.check(amount,open3);
        require(isverify,"amount error");
        require(wallet[addr][reVer].status==0||wallet[addr][reVer].status==1,"Assets already in investment");
        if(accounts[addr].valid == 0){
            handel(addr,amount,reAddr,lv,0);
        }else{
            handel(addr,amount,accounts[addr].raddr,lv,1);
        }
    }
    function withdraw(uint8 withtype) public{
        require(accounts[msg.sender].valid>0&&isRestart==0&&withtype>=2&&withtype<=3, "Invalid operation");
        uint balance = 0;
        if(withtype==2){
            balance = wallet[msg.sender][reVer].amount;
        }else if(withtype==3){
            balance = wallet[msg.sender][reVer].profit;
        }
        (bool isCan,uint amount) = utils.isSufficient(balance,betPool,riskPool,address(this).balance);
        require(amount>0&&balance>=amount, "Insufficient withdrawable amount");
        if(withtype==2){
            wallet[msg.sender][reVer].amount = wallet[msg.sender][reVer].amount-amount;
        }else if(withtype==3){
            wallet[msg.sender][reVer].profit = wallet[msg.sender][reVer].profit-amount;
        }
        if(!isCan){
            EventRestart();
        }
        emit Extract(msg.sender,amount,withtype);
        msg.sender.transfer(amount);
    }
    function sendRisk(uint payamount) private{
        invest_total = invest_total+payamount;
        UserCount = UserCount+1;
        uint riskAmount = payamount*6/100;
        uint adminMoeny = payamount/25;
        riskPool = riskPool+riskAmount;
        betPool = betPool+(payamount-riskPool-adminMoeny);
        if(address(this).balance>=adminMoeny){
            address payable SendCommunity = 0x493601dAFE2D6c6937df3f0AD13Fa6bAF12dFa00;
            SendCommunity.transfer(adminMoeny);
        }
    }
    function getInfo() public view returns(uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256){
        uint256 blance = address(this).balance;
        return (InvsetIndex,betPool,riskPool,invest_total,UserCount,online,reVer,open3,isRestart,start_time,blance,revert_last_invest);
    }
    function getInv(uint arrayIndex) public view IsManage returns(uint,uint8,uint8,address,uint8,uint,address,uint,uint8,uint){
        LuckUtils.Invset memory inv = invsets[arrayIndex];
        return (inv.amount,inv.lv,inv.day,inv.addr,inv.notDone,inv.time,accounts[inv.addr].raddr,isRestart,inv.share,reVer);
    }
    function lastInvest() public view returns(address[] memory){
        if(UserCount<=100){
            address[] memory notLastAssr = new address[](0);
            return notLastAssr;
        }
        uint lastIndex = InvsetIndex;
        address[] memory lastAddr = new address[](100);
        for(uint i = 0;i<100;i = i+1){
            if(invsets[lastIndex-i].amount<=0){
                return (lastAddr);
            }
            lastAddr[i] = invsets[lastIndex-i].addr;
        }
        return (lastAddr);
    }
    function remAddr(address addr,uint page) public view returns(address[] memory,uint[] memory,uint[] memory){
        require(page>0,"Invalid page number");
        if(RemAddrs[addr].length<=0){
            return (new address[](0),new uint[](0),new uint[](0));
        }
        address[] memory rAddr = new address[](10);
        uint[] memory rInvAm = new uint[](10);
        uint[] memory rNum = new uint[](10);
        uint startIdx = (page-1)*10;
        for(uint i = 0;i<=10&&i+startIdx<RemAddrs[addr].length;i = i+1){
            address  itemAddr = RemAddrs[addr][startIdx+i];
            rAddr[i] = itemAddr;
            if(wallet[itemAddr][reVer].status==2){
                rInvAm[i] = wallet[itemAddr][reVer].last_invest;
            }
            rNum[i] = RemAddrs[itemAddr].length;
        }
        return (rAddr,rInvAm,rNum);
    }
    function journal()public view returns(uint[] memory,uint[] memory){
        uint[] memory amount = new uint[](20);
        uint[] memory time = new uint[](20);
        uint data_index = 0;
        for(uint i = IncomeRecord[msg.sender].length+10;i>10&&data_index<20;i = i-1){
            LuckUtils.Journal memory jrnal = IncomeRecord[msg.sender][i-11];
            amount[data_index] = jrnal.amount;
            time[data_index] = jrnal.time;
            data_index = data_index+1;
        }
        return (amount,time);
    }
    function GetCode(uint code)public view returns(address){
        return CodeMapAddr[code];
    }
    function userInfo(address addr) public view returns(uint256[] memory){
        require(msg.sender==addr||manage[msg.sender]==1||msg.sender==owner,"not found");
        LuckUtils.Wallet memory myWalt = wallet[addr][reVer];
        uint256[] memory lastAddr = new uint256[](14);
        lastAddr[0] = myWalt.amount;
        lastAddr[1] = myWalt.profit_s;
        lastAddr[2] = myWalt.last_invest;
        lastAddr[3] = myWalt.profit_d;
        lastAddr[4] = myWalt.profit;
        lastAddr[5] = invsets[myWalt.index].amount;
        lastAddr[6] = myWalt.status;
        lastAddr[7] = invsets[myWalt.index].day;
        lastAddr[8] = invsets[myWalt.index].lv;
        lastAddr[9] = invsets[myWalt.index].time;
        lastAddr[10] = myWalt.rn;
        lastAddr[11] = myWalt.index;
        lastAddr[12] = accounts[addr].valid;
        lastAddr[13] = accounts[addr].recode;

        return lastAddr;
    }
    function setManage(address addr,uint status) public IsOwner{
        if(status==1){
            manage[addr] = 1;
        }else{
            manage[addr] = 0;
        }
    }
}
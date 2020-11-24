 

pragma solidity ^0.5.0;

library SafeMath {
  function sub(uint a, uint b) internal pure returns (uint) {
    require(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal pure returns (uint) {
    uint c = a + b;
    require(c >= a);
    return c;
  }
   
}

contract ERC20Basic {
  uint public totalSupply;
  address public owner;  
  function balanceOf(address who) public view returns (uint);
  function transfer(address to, uint value) public;
  event Transfer(address indexed from, address indexed to, uint value);
  function commitDividend(address who) public;  
}

contract ERC20 is ERC20Basic {
  function allowance(address owner, address spender) public view returns (uint);
  function transferFrom(address from, address to, uint value) public;
  function approve(address spender, uint value) public;
  event Approval(address indexed owner, address indexed spender, uint value);
}

contract BasicToken is ERC20Basic {
  using SafeMath for uint;
   
  struct User {
    uint120 tokens;  
    uint120 asks;    
    uint120 votes;   
    uint120 weis;    
    uint32 lastProposalID;  
    address owner;   
    uint8   voted;   
  }
  mapping (address => User) users;

  modifier onlyPayloadSize(uint size) {
    assert(msg.data.length >= size + 4);
    _;
  }
   
  function transfer(address _to, uint _value) public onlyPayloadSize(2 * 32) {
    commitDividend(msg.sender);
    users[msg.sender].tokens = uint120(uint(users[msg.sender].tokens).sub(_value));
    if(_to == address(this)) {
      commitDividend(owner);
      users[owner].tokens = uint120(uint(users[owner].tokens).add(_value));
      emit Transfer(msg.sender, owner, _value);
    }
    else {
      commitDividend(_to);
      users[_to].tokens = uint120(uint(users[_to].tokens).add(_value));
      emit Transfer(msg.sender, _to, _value);
    }
  }
   
  function balanceOf(address _owner) public view returns (uint) {
    return uint(users[_owner].tokens);
  }
   
  function askOf(address _owner) public view returns (uint) {
    return uint(users[_owner].asks);
  }
   
  function voteOf(address _owner) public view returns (uint) {
    return uint(users[_owner].votes);
  }
   
  function weiOf(address _owner) public view returns (uint) {
    return uint(users[_owner].weis);
  }
   
  function lastOf(address _owner) public view returns (uint) {
    return uint(users[_owner].lastProposalID);
  }
   
  function ownerOf(address _owner) public view returns (address) {
    return users[_owner].owner;
  }
   
  function votedOf(address _owner) public view returns (uint) {
    return uint(users[_owner].voted);
  }
}

contract StandardToken is BasicToken, ERC20 {
  mapping (address => mapping (address => uint)) allowed;

   
  function transferFrom(address _from, address _to, uint _value) public onlyPayloadSize(3 * 32) {
    uint _allowance = allowed[_from][msg.sender];
    commitDividend(_from);
    commitDividend(_to);
    allowed[_from][msg.sender] = _allowance.sub(_value);
    users[_from].tokens = uint120(uint(users[_from].tokens).sub(_value));
    users[_to].tokens = uint120(uint(users[_to].tokens).add(_value));
    emit Transfer(_from, _to, _value);
  }
   
  function approve(address _spender, uint _value) public {
     
    assert(!((_value != 0) && (allowed[msg.sender][_spender] != 0)));
    allowed[msg.sender][_spender] = _value;
    emit Approval(msg.sender, _spender, _value);
  }
   
  function allowance(address _owner, address _spender) public view returns (uint remaining) {
    return allowed[_owner][_spender];
  }
}

 
contract PicoStocksAsset is StandardToken {

     
    string public constant version = "0.2";
    string public constant name = "PicoStocks Asset";
    uint public constant decimals = 0;
    uint public picoid = 0;  
    string public symbol = "";  
    string public www = "";  

    uint public totalWeis = 0;  
    uint public totalVotes = 0;   

    struct Order {
        uint64 prev;    
        uint64 next;    
        uint128 price;  
        uint96 amount;  
        address who;    
    }
    mapping (uint => Order) asks;
    mapping (uint => Order) bids;
    uint64 firstask=0;  
    uint64 lastask=0;   
    uint64 firstbid=0;  
    uint64 lastbid=0;   

    uint constant weekBlocks = 4*60*24*7;  
    uint constant minPrice  = 0xFFFF;                              
    uint constant maxPrice  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;  
    uint constant maxTokens = 0xFFFFFFFFFFFFFFFFFFFFFFFF;          

    address public custodian = 0xd720a4768CACE6d508d8B390471d83BA3aE6dD32;

     
    uint public investOwner;  
    uint public investPrice;  
    uint public investStart;  
    uint public investEnd;    
    uint public investGot;    
    uint public investMin;    
    uint public investMax;    
    uint public investKYC = 1;    

     
    uint[] public dividends;  

     
    uint public proposalID = 1;    
    uint public proposalVotesYes;  
    uint public proposalVotesNo;   
    uint public proposalBlock;     
    uint public proposalDividendPerShare;  
    uint public proposalBudget;    
    uint public proposalTokens;    
    uint public proposalPrice;     
    uint public acceptedBudget;    

     
    mapping (address => uint) owners;  

     
    event LogBuy(address indexed who, uint amount, uint price);
    event LogSell(address indexed who, uint amount, uint price);
    event LogCancelBuy(address indexed who, uint amount, uint price);
    event LogCancelSell(address indexed who, uint amount, uint price);
    event LogTransaction(address indexed from, address indexed to, uint amount, uint price);
    event LogDeposit(address indexed who,uint amount);
    event LogWithdraw(address indexed who,uint amount);
    event LogExec(address indexed who,uint amount);
    event LogPayment(address indexed who, address from, uint amount);
    event LogDividend(uint amount);
    event LogDividend(address indexed who, uint amount, uint period);
    event LogNextInvestment(uint price,uint amount);
    event LogNewOwner(address indexed who);
    event LogNewCustodian(address indexed who);
    event LogNewWww(string www);
    event LogProposal(uint dividendpershare,uint budget,uint moretokens,uint minprice);
    event LogVotes(uint proposalVotesYes,uint proposalVotesNo);
    event LogBudget(uint proposalBudget);
    event LogAccepted(uint proposalDividendPerShare,uint proposalBudget,uint proposalTokens,uint proposalPrice);
    event LogRejected(uint proposalDividendPerShare,uint proposalBudget,uint proposalTokens,uint proposalPrice);
    
    modifier onlyOwner() {
        assert(msg.sender == owner);
        _;
    }

     
     
    constructor() public {
        owner = msg.sender;
    }

 

     
    function setFirstInvestPeriod(uint _tokens,uint _budget,uint _price,uint _from,uint _length,uint _min,uint _max,uint _kyc,uint _picoid,string memory _symbol) public onlyOwner {
        require(investEnd == 0 && _price < maxPrice && _length <= weekBlocks * 12 && _min <= _max && _tokens.add(_max) < maxTokens );
        investOwner = _tokens;
        acceptedBudget = _budget;
        users[owner].lastProposalID = uint32(proposalID);
        users[custodian].lastProposalID = uint32(proposalID);
        if(_price <= minPrice){
          _price = minPrice+1;
        }
        investPrice = _price;
        if(_from < block.number){
          _from = block.number;
        }
        investStart = _from;
        if(_length == 0){
          _length = weekBlocks * 4;
        }
        investEnd = _from + _length;
        investMin = _min;
        investMax = _max;
        investKYC = _kyc;
        picoid = _picoid;
        symbol = _symbol;
        dividends.push(0);  
        dividends.push(0);  
        if(investMax == 0){
          closeInvestPeriod();
        }
    }

     
    function acceptKYC(address _who) external onlyOwner {
        if(users[_who].lastProposalID==0){
          users[_who].lastProposalID=1;
        }
    }

     
    function invest() payable public {
        commitDividend(msg.sender);
        require(msg.value > 0 && block.number >= investStart && block.number < investEnd && totalSupply < investMax && investPrice > 0);
        uint tokens = msg.value / investPrice;
        if(investMax < totalSupply.add(tokens)){
            tokens = investMax.sub(totalSupply);
        }
        totalSupply += tokens;
        users[msg.sender].tokens += uint120(tokens);
        emit Transfer(address(0),msg.sender,tokens);
        uint _value = msg.value.sub(tokens * investPrice);
        if(_value > 0){  
            emit LogWithdraw(msg.sender,_value);
            (bool success,  ) = msg.sender.call.value(_value)("");
            require(success);
        }
        if(totalSupply>=investMax){
            closeInvestPeriod();
        }
    }

     
    function () payable external {
        invest();
    }

     
    function disinvest() public {
        require(investEnd < block.number && totalSupply < investMin && totalSupply>0 && proposalID > 1);
        payDividend((address(this).balance-totalWeis)/totalSupply);  
        investEnd = block.number + weekBlocks*4;  
    }

 

     
    function propose(uint _dividendpershare,uint _budget,uint _tokens,uint _price) external onlyOwner {
        require(proposalBlock + weekBlocks*4 < block.number && investEnd < block.number && proposalID > 1);  
        if(block.number>investEnd && investStart>0 && investPrice>0 && investMax>0){
          totalVotes=totalSupply;
          investStart=0;
          investMax=0;
        }
        proposalVotesYes=0;
        proposalVotesNo=0;
        proposalID++;
        dividends.push(0);
        proposalBlock=block.number;
        proposalDividendPerShare=_dividendpershare;
        proposalBudget=_budget;
        proposalTokens=_tokens;
        proposalPrice=_price;
        emit LogProposal(_dividendpershare,_budget,_tokens,_price);
    }

     
    function executeProposal() public {
        require(proposalVotesYes > 0 && (proposalBlock + weekBlocks*4 < block.number || proposalVotesYes>totalVotes/2 || proposalVotesNo>totalVotes/2) && proposalID > 1);
         
        emit LogVotes(proposalVotesYes,proposalVotesNo);
        if(proposalVotesYes >= proposalVotesNo && (proposalTokens==0 || proposalPrice>=investPrice || proposalVotesYes>totalVotes/2)){
          if(payDividend(proposalDividendPerShare) > 0){
            emit LogBudget(proposalBudget);
            acceptedBudget=proposalBudget;}
          if(proposalTokens>0){
            emit LogNextInvestment(proposalPrice,proposalTokens);
            setNextInvestPeriod(proposalPrice,proposalTokens);}
          emit LogAccepted(proposalDividendPerShare,proposalBudget,proposalTokens,proposalPrice);}
        else{
          emit LogRejected(proposalDividendPerShare,proposalBudget,proposalTokens,proposalPrice);}
        proposalBlock=0;
        proposalVotesYes=0;
        proposalVotesNo=0;
        proposalDividendPerShare=0;
        proposalBudget=0;
        proposalTokens=0;
        proposalPrice=0;
    }

     
    function setNextInvestPeriod(uint _price,uint _tokens) internal {
        require(totalSupply >= investMin && _price > 0 && _price < maxPrice && totalSupply + _tokens < 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        investStart = block.number + weekBlocks*2;
        investEnd = block.number + weekBlocks*4;
        investPrice = _price;  
        investMax = totalSupply + _tokens;
        investKYC=0;
    }

     
    function closeInvestPeriod() public {
        require((block.number>investEnd || totalSupply>=investMax) && investStart>0);
        if(proposalID == 1){
          totalSupply += investOwner;
          users[owner].tokens += uint120(investOwner);
          if(totalSupply == 0){
            totalSupply = 1;
            users[owner].tokens = 1;
          }
        }
        proposalID++;
        dividends.push(0);
        totalVotes=totalSupply;
        investStart=0;
        investMax=0;
        investKYC=0;
    }

     
    function payDividend(uint _wei) internal returns (uint) {
        if(_wei == 0){
          return 1;}
         
        uint newdividend = _wei * totalSupply;
        require(newdividend / _wei == totalSupply);
        if(address(this).balance < newdividend.add(totalWeis)){
          emit LogDividend(0);  
          return 0;}
        totalWeis += newdividend;
        dividends[proposalID] = _wei;
        proposalID++;
        dividends.push(0);
        totalVotes=totalSupply;
        emit LogDividend(_wei);
        return(_wei);
    }

     
    function commitDividend(address _who) public {
        uint last = users[_who].lastProposalID;
        require(investKYC==0 || last>0);  
        uint tokens=users[_who].tokens+users[_who].asks;
        if((tokens==0) || (last==0)){
            users[_who].lastProposalID=uint32(proposalID);
            return;
        }
        if(last==proposalID) {
            return;
        }
        if(tokens != users[_who].votes){
            if(users[_who].owner != address(0)){
                owners[users[_who].owner] = owners[users[_who].owner].add(tokens).sub(uint(users[_who].votes));
            }
            users[_who].votes=uint120(tokens);  
        }
        uint balance = 0;
        for(; last < proposalID ; last ++) {
            balance += tokens * dividends[last];
        }
        users[_who].weis += uint120(balance);
        users[_who].lastProposalID = uint32(last);
        users[_who].voted=0;
        emit LogDividend(_who,balance,last);
    }

 

     
    function changeOwner(address _who) external onlyOwner {
        assert(_who != address(0));
        owner = _who;
        emit LogNewOwner(_who);
    }

     
    function changeWww(string calldata _www) external onlyOwner {
        www=_www;
        emit LogNewWww(_www);
    }

     
    function changeCustodian(address _who) external {  
        assert(msg.sender == custodian);
        assert(_who != address(0));
        custodian = _who;
        emit LogNewCustodian(_who);
    }

     
    function exec(address _to,bytes calldata _data) payable external onlyOwner {
        emit LogExec(_to,msg.value);
        (bool success,  ) =_to.call.value(msg.value)(_data);
        require(success);
    }

     
    function spend(uint _amount,address _who) external onlyOwner {
        require(_amount > 0 && address(this).balance >= _amount.add(totalWeis) && totalSupply >= investMin);
        acceptedBudget=acceptedBudget.sub(_amount);  
        if(_who == address(0)){
          emit LogWithdraw(msg.sender,_amount);
          (bool success,  ) = msg.sender.call.value(_amount)("");
          require(success);}
        else{
          emit LogWithdraw(_who,_amount);
          (bool success,  ) = _who.call.value(_amount)("");
          require(success);}
    }

 

     
    function voteOwner(address _who) external {
        require(_who != users[msg.sender].owner);
        if(users[msg.sender].owner != address(0)){
          owners[users[msg.sender].owner] = owners[users[msg.sender].owner].sub(users[msg.sender].votes);
        }
        users[msg.sender].owner=_who;
        if(_who != address(0)){
          owners[_who] = owners[_who].add(users[msg.sender].votes);
          if(owners[_who] > totalVotes/2 && _who != owner){
            owner = _who;
            emit LogNewOwner(_who);
          }
        }
    }

     
    function voteYes() public {
        commitDividend(msg.sender);
        require(users[msg.sender].voted == 0 && proposalBlock + weekBlocks*4 > block.number && proposalBlock > 0);
        users[msg.sender].voted=1;
        proposalVotesYes+=users[msg.sender].votes;
    }

     
    function voteNo() public {
        commitDividend(msg.sender);
        require(users[msg.sender].voted == 0 && proposalBlock + weekBlocks*4 > block.number && proposalBlock > 0);
        users[msg.sender].voted=1;
        proposalVotesNo+=users[msg.sender].votes;
    }

     
    function voteYes(uint _id) external {
        require(proposalID==_id);
        voteYes();
    }

     
    function voteNo(uint _id) external {
        require(proposalID==_id);
        voteNo();
    }

     
    function deposit() payable external {
        commitDividend(msg.sender);  
        users[msg.sender].weis += uint120(msg.value);
        totalWeis += msg.value;
        emit LogDeposit(msg.sender,msg.value);
    }

     
    function withdraw(uint _amount) external {
        commitDividend(msg.sender);
        uint amount=_amount;
        if(amount > 0){
           require(users[msg.sender].weis >= amount);
        }
        else{
           require(users[msg.sender].weis > 0);
           amount=users[msg.sender].weis;
        }
        users[msg.sender].weis = uint120(uint(users[msg.sender].weis).sub(amount));
        totalWeis = totalWeis.sub(amount);
         
        emit LogWithdraw(msg.sender,amount);
        (bool success,  ) = msg.sender.call.value(amount)("");
        require(success);
    }

     
    function wire(uint _amount,address _who) external {
        users[msg.sender].weis = uint120(uint(users[msg.sender].weis).sub(_amount));
        users[_who].weis = uint120(uint(users[_who].weis).add(_amount));
    }

     
    function pay(address _who) payable external {
        emit LogPayment(_who,msg.sender,msg.value);
    }

 

     
    function ordersSell(address _who) external view returns (uint[256] memory) {
        uint[256] memory ret;
        uint num=firstask;
        uint id=0;
        for(;asks[num].price>0 && id<64;num=uint(asks[num].next)){
          if(_who!=address(0) && _who!=asks[num].who){
            continue;
          }
          ret[4*id+0]=num;
          ret[4*id+1]=uint(asks[num].price);
          ret[4*id+2]=uint(asks[num].amount);
          ret[4*id+3]=uint(asks[num].who);
          id++;}
        return ret;
    }

     
    function ordersBuy(address _who) external view returns (uint[256] memory) {
        uint[256] memory ret;
        uint num=firstbid;
        uint id=0;
        for(;bids[num].price>0 && id<64;num=uint(bids[num].next)){
          if(_who!=address(0) && _who!=bids[num].who){
            continue;
          }
          ret[4*id+0]=num;
          ret[4*id+1]=uint(bids[num].price);
          ret[4*id+2]=uint(bids[num].amount);
          ret[4*id+3]=uint(bids[num].who);
          id++;}
        return ret;
    }

     
    function findSell(address _who,uint _minprice,uint _maxprice) external view returns (uint) {
        uint num=firstask;
        for(;asks[num].price>0;num=asks[num].next){
          if(_maxprice > 0 && asks[num].price > _maxprice){
            return 0;}
          if(_minprice > 0 && asks[num].price < _minprice){
            continue;}
          if(_who == asks[num].who){  
            return num;}}
    }

     
    function findBuy(address _who,uint _minprice,uint _maxprice) external view returns (uint) {
        uint num=firstbid;
        for(;bids[num].price>0;num=bids[num].next){
          if(_minprice > 0 && bids[num].price < _minprice){
            return 0;}
          if(_maxprice > 0 && bids[num].price > _maxprice){
            continue;}
          if(_who == bids[num].who){
            return num;}}
    }

     
    function whoSell(uint _id) external view returns (address) {
        if(_id>0){
          return address(asks[_id].who);
        }
        return address(asks[firstask].who);
    }

     
    function whoBuy(uint _id) external view returns (address) {
        if(_id>0){
          return address(bids[_id].who);
        }
        return address(bids[firstbid].who);
    }

     
    function amountSell(uint _id) external view returns (uint) {
        if(_id>0){
          return uint(asks[_id].amount);
        }
        return uint(asks[firstask].amount);
    }

     
    function amountBuy(uint _id) external view returns (uint) {
        if(_id>0){
          return uint(bids[_id].amount);
        }
        return uint(bids[firstbid].amount);
    }

     
    function priceSell(uint _id) external view returns (uint) {
        if(_id>0){
          return uint(asks[_id].price);
        }
        return uint(asks[firstask].price);
    }

     
    function priceBuy(uint _id) external view returns (uint) {
        if(_id>0){
          return uint(bids[_id].price);
        }
        return uint(bids[firstbid].price);
    }

 

     
    function cancelSell(uint _id) external {
        require(asks[_id].price>0 && asks[_id].who==msg.sender);
        users[msg.sender].tokens=uint120(uint(users[msg.sender].tokens).add(asks[_id].amount));
        users[msg.sender].asks=uint120(uint(users[msg.sender].asks).sub(asks[_id].amount));
        if(asks[_id].prev>0){
          asks[asks[_id].prev].next=asks[_id].next;}
        else{
          firstask=asks[_id].next;}
        if(asks[_id].next>0){
          asks[asks[_id].next].prev=asks[_id].prev;}
        emit LogCancelSell(msg.sender,asks[_id].amount,asks[_id].price);
        delete(asks[_id]);
    }

     
    function cancelBuy(uint _id) external {
        require(bids[_id].price>0 && bids[_id].who==msg.sender);
        uint value=bids[_id].amount*bids[_id].price;
        users[msg.sender].weis+=uint120(value);
        if(bids[_id].prev>0){
          bids[bids[_id].prev].next=bids[_id].next;}
        else{
          firstbid=bids[_id].next;}
        if(bids[_id].next>0){
          bids[bids[_id].next].prev=bids[_id].prev;}
        emit LogCancelBuy(msg.sender,bids[_id].amount,bids[_id].price);
        delete(bids[_id]);
    }

     
    function sell(uint _amount, uint _price) external {
        require(0 < _price && _price < maxPrice && 0 < _amount && _amount < maxTokens && _amount <= users[msg.sender].tokens);
        commitDividend(msg.sender);
        users[msg.sender].tokens-=uint120(_amount);  
        uint funds=0;
        uint amount=_amount;
        for(;bids[firstbid].price>0 && bids[firstbid].price>=_price;){
          uint value=uint(bids[firstbid].price)*uint(bids[firstbid].amount);
          uint fee=value >> 9;  
          if(amount>=bids[firstbid].amount){
            amount=amount.sub(uint(bids[firstbid].amount));
            commitDividend(bids[firstbid].who);
            emit LogTransaction(msg.sender,bids[firstbid].who,bids[firstbid].amount,bids[firstbid].price);
             
             
            funds=funds.add(value-fee-fee);
            users[custodian].weis+=uint120(fee);
            totalWeis=totalWeis.sub(fee);
             
            users[bids[firstbid].who].tokens+=bids[firstbid].amount;
             
            uint64 next=bids[firstbid].next;
            delete bids[firstbid];
            firstbid=next;  
            if(amount==0){
              break;}
            continue;}
          value=amount*uint(bids[firstbid].price);
          fee=value >> 9;  
          commitDividend(bids[firstbid].who);
          funds=funds.add(value-fee-fee);
          emit LogTransaction(msg.sender,bids[firstbid].who,amount,bids[firstbid].price);
           
           
          users[custodian].weis+=uint120(fee);
          totalWeis=totalWeis.sub(fee);
          bids[firstbid].amount=uint96(uint(bids[firstbid].amount).sub(amount));
          require(bids[firstbid].amount>0);
           
          users[bids[firstbid].who].tokens+=uint120(amount);
          bids[firstbid].prev=0;
          totalWeis=totalWeis.sub(funds);
          (bool success,  ) = msg.sender.call.value(funds)("");
          require(success);
          return;}
        if(firstbid>0){
          bids[firstbid].prev=0;}
        if(amount>0){
          uint64 ask=firstask;
          uint64 last=0;
          for(;asks[ask].price>0 && asks[ask].price<=_price;ask=asks[ask].next){
            last=ask;}
          lastask++;
          asks[lastask].prev=last;
          asks[lastask].next=ask;
          asks[lastask].price=uint128(_price);
          asks[lastask].amount=uint96(amount);
          asks[lastask].who=msg.sender;
          users[msg.sender].asks+=uint120(amount);
          emit LogSell(msg.sender,amount,_price);
          if(last>0){
            asks[last].next=lastask;}
          else{
            firstask=lastask;}
          if(ask>0){
            asks[ask].prev=lastask;}}
        if(funds>0){
          totalWeis=totalWeis.sub(funds);
          (bool success,  ) = msg.sender.call.value(funds)("");
          require(success);}
    }

     
    function buy(uint _amount, uint _price) payable external {
        require(0 < _price && _price < maxPrice && 0 < _amount && _amount < maxTokens && _price <= msg.value);
        commitDividend(msg.sender);
        uint funds=msg.value;
        uint amount=_amount;
        uint value;
        for(;asks[firstask].price>0 && asks[firstask].price<=_price;){
          value=uint(asks[firstask].price)*uint(asks[firstask].amount);
          uint fee=value >> 9;  
          if(funds>=value+fee+fee && amount>=asks[firstask].amount){
            amount=amount.sub(uint(asks[firstask].amount));
            commitDividend(asks[firstask].who);
            funds=funds.sub(value+fee+fee);
            emit LogTransaction(asks[firstask].who,msg.sender,asks[firstask].amount,asks[firstask].price);
             
            users[asks[firstask].who].asks-=asks[firstask].amount;
            users[asks[firstask].who].weis+=uint120(value);
            users[custodian].weis+=uint120(fee);
            totalWeis=totalWeis.add(value+fee);
             
            users[msg.sender].tokens+=asks[firstask].amount;
             
            uint64 next=asks[firstask].next;
            delete asks[firstask];
            firstask=next;  
            if(funds<asks[firstask].price){
              break;}
            continue;}
          if(amount>asks[firstask].amount){
            amount=asks[firstask].amount;}
          if((funds-(funds>>8))<amount*asks[firstask].price){
            amount=(funds-(funds>>8))/asks[firstask].price;}
          if(amount>0){
            value=amount*uint(asks[firstask].price);
            fee=value >> 9;  
            commitDividend(asks[firstask].who);
            funds=funds.sub(value+fee+fee);
            emit LogTransaction(asks[firstask].who,msg.sender,amount,asks[firstask].price);
             
            users[asks[firstask].who].asks-=uint120(amount);
            users[asks[firstask].who].weis+=uint120(value);
            users[custodian].weis+=uint120(fee);
            totalWeis=totalWeis.add(value+fee);
            asks[firstask].amount=uint96(uint(asks[firstask].amount).sub(amount));
            require(asks[firstask].amount>0);
             
            users[msg.sender].tokens+=uint120(amount);}
          asks[firstask].prev=0;
          if(funds>0){
            (bool success,  ) = msg.sender.call.value(funds)("");
            require(success);}
          return;}
        if(firstask>0){  
          asks[firstask].prev=0;}
        if(amount>funds/_price){
          amount=funds/_price;}
        if(amount>0){
          uint64 bid=firstbid;
          uint64 last=0;
          for(;bids[bid].price>0 && bids[bid].price>=_price;bid=bids[bid].next){
            last=bid;}
          lastbid++;
          bids[lastbid].prev=last;
          bids[lastbid].next=bid;
          bids[lastbid].price=uint128(_price);
          bids[lastbid].amount=uint96(amount);
          bids[lastbid].who=msg.sender;
          value=amount*_price;
          totalWeis=totalWeis.add(value);
          funds=funds.sub(value);
          emit LogBuy(msg.sender,amount,_price);
          if(last>0){
            bids[last].next=lastbid;}
          else{
            firstbid=lastbid;}
          if(bid>0){
            bids[bid].prev=lastbid;}}
        if(funds>0){
          (bool success,  ) = msg.sender.call.value(funds)("");
          require(success);}
    }

}
 

pragma solidity ^0.4.17;

 
 
contract LoveBankAccessControl {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    event ContractUpgrade(address newVerseContract);

     
    address public ceoAddress;
    address public cfoAddress;
    address public cooAddress;

     
    bool public paused=false;

     
    modifier onlyCEO() {
        require(msg.sender == ceoAddress);
        _;
    }

     
    modifier onlyCFO() {
        require(msg.sender == cfoAddress);
        _;
    }

     
    modifier onlyCOO() {
        require(msg.sender == cooAddress);
        _;
    }

    modifier onlyCLevel() {
        require(
            msg.sender == cooAddress ||
            msg.sender == ceoAddress ||
            msg.sender == cfoAddress
        );
        _;
    }
    
     
     
    function setCEO(address _newCEO) external onlyCEO {
        require(_newCEO != address(0));
        ceoAddress = _newCEO;
    }

     
     
    function setCFO(address _newCFO) external onlyCEO {
        require(_newCFO != address(0));
        cfoAddress = _newCFO;
    }

     
     
    function setCOO(address _newCOO) external onlyCEO {
        require(_newCOO != address(0));
        cooAddress = _newCOO;
    }
    
     

     
    modifier whenNotPaused() {
        require(!paused);
        _;
    }

     
    modifier whenPaused() {
        require(paused);
        _;
    }

     
     
    function pause() external onlyCLevel whenNotPaused {
        paused = true;
    }

     
     
     
     
     
    function unpause() public onlyCEO whenPaused {
         
        paused = false;
    }
}

 
 
 
 

contract LoveAccountBase{

     
     
     
     
     
     
     
     
     
     
     
     
     
     

     
    
     
    event Deposit(address _from, uint _value);
    
     
     
    enum Status{BreakUp, Active, RequestPending, FirstMet,   
        FirstKiss, FirstConfess, InRelationship,FirstDate,  
        Proposal, Engage, WeddingDay, Anniversary, Trip,   
        NewFamilyMember, FirstSex, Birthday,              
        special1, special2, special3                   
    }

    struct StonePage {
    	uint64 logtime;
    	Status contant;
    }

    struct DiaryPage {
    	uint64 logtime;
    	bytes contant;
    }

     
    
     
    bytes32 public name1;

     
    bytes32 public name2;

     
    address public owner1;

     
    address public owner2;

     
    address BANKACCOUNT;

     
    address withdrawer;

     
    uint256 request_amount;

     
    uint256 request_fee;

     
    uint64 public loveID;

     
    uint64 public foundTime=uint64(now);

     
    uint64 public next_diary_id=0;

     
    uint64 public next_stone_id=0;

     
    Status public status=Status.Active;
    
     
    mapping (uint64=>StonePage) public milestone;

     
    mapping (uint64=>DiaryPage) public diary;

     
    function LoveAccountBase (
        bytes32 _name1,
        bytes32 _name2,
        address _address1,
        address _address2,
        uint64 _loveID) public {
            name1 = _name1;
            name2 = _name2;
            owner1 = _address1;
            owner2 = _address2;
            loveID = _loveID;
            BANKACCOUNT = msg.sender;
    }
     
    modifier notBreakup() {require(uint(status)!=0);_;}

     
    modifier oneOfOwners(address _address) {
        require (_address==owner1 || _address==owner2);_;
    }

     
    modifier callByBank() {require(msg.sender == BANKACCOUNT);_;}
    
     
    function changeBankAccount(address newBank) external callByBank{
        require(newBank!=address(0));
        BANKACCOUNT = newBank;
    }

     
     
     
    function breakup(
        address _breaker, uint256 _fee) external payable 
        notBreakup oneOfOwners(_breaker) callByBank{
        if(_fee!=0){BankCore(BANKACCOUNT).receiveFee.value(_fee)();}
        if(_breaker==owner1) {owner2.transfer(this.balance);}
        if(_breaker==owner2) {owner1.transfer(this.balance);}
        status=Status.BreakUp;
    }
    
     
    function withdraw(uint256 amount, 
        address _to, uint256 _fee) external notBreakup oneOfOwners(_to) callByBank{
        require(this.balance>=amount);
         
        status =Status.RequestPending;
        request_amount = amount;
        withdrawer = _to;
        request_fee = _fee;
    }

     
    function withdrawConfirm(
        uint256 _amount, 
        address _confirmer) external payable notBreakup oneOfOwners(_confirmer) callByBank{
         
        require(uint(status)==2);
        require(_amount==request_amount);
        require(_confirmer!=withdrawer);
        require(this.balance>=request_amount);
        
         
        if(request_fee!=0){BankCore(BANKACCOUNT).receiveFee.value(request_fee)();}
        withdrawer.transfer(request_amount-request_fee);

         
        status=Status.Active;
        withdrawer=address(0);
        request_amount=0;
        request_fee=0;
    }
    
     
    function mileStone(address _sender, uint64 _time, uint8 _choice) external notBreakup oneOfOwners(_sender) callByBank {
        milestone[next_stone_id]=StonePage({
        	logtime: _time,
        	contant: Status(_choice)
        });
        next_stone_id++;
    }

     
    function Diary(address _sender, bytes _diary) external notBreakup oneOfOwners(_sender) callByBank {
        diary[next_diary_id]=DiaryPage({
        	logtime: uint64(now),
        	contant: _diary
        });
        next_diary_id++;  
    }
    
     
    function() external payable notBreakup {
        require(msg.value>0);
        Deposit(msg.sender, msg.value);
    }
}


 
 
 
contract Bank is LoveBankAccessControl{

     

     
     
    event Create(bytes32 _name1, bytes32 _name2, address _conadd, 
                address _address1, address _address2, uint64 _loveID);
     
    event Breakup(uint _time);
     
    event StoneLog(uint _time, uint _choice);
     
    event DiaryLog(uint _time, bytes _contant);
     
    event Withdraw(uint _amount, uint _endTime);
     
    event WithdrawConfirm(uint _amount, uint _confirmTime);

     
    
    struct pending {
        bool pending;
        address withdrawer;
        uint256 amount;
        uint256 fee;
        uint64 endTime;
    }

     

     
    uint256 STONE_FEE=4000000000000000;
    uint256 OPEN_FEE=20000000000000000;
    uint64 FREE_START=0;
    uint64 FREE_END=0;
    uint64 WD_FEE_VERSE=100;   
    uint64 BU_FEE_VERSE=50;    
    uint32 public CONFIRM_LIMIT = 900;  

     

     
    uint64 public next_id=0; 
     
    mapping (bytes16 => address)  public sig_to_add;
     
    mapping (address => pending) public pendingList;
    
     
     
     
     
     
    function createAccount(
        bytes32 name1,
        bytes32 name2,
        address address1,
        address address2) external payable whenNotPaused {
        uint fee;
         
        if (_ifFree()){fee=0;} else{fee=OPEN_FEE;}
        require(msg.sender==address1   &&
                address1!=address2     && 
                address1!=address(0)   &&
                address2!=address(0)   &&
                msg.value>=fee);
        require(_ifFree() || msg.value >= OPEN_FEE);
         
        bytes16 sig = bytes16(keccak256(address1))^bytes16(keccak256(address2));
        require(sig_to_add[sig]==0);
         
        address newContract = (new LoveAccountBase)(name1, name2, address1, address2, next_id);
        sig_to_add[sig]=newContract;
        Create(name1, name2, newContract, address1, address2, next_id);
         
        if(msg.value>fee){
            newContract.transfer(msg.value-fee);
        }
        next_id++;
    }
    
     
     
    function _calculate(uint256 _amount, uint _dev) internal pure returns(uint256 _int){
        _int = _amount/uint256(_dev);
    }

     
    function _ifFree() view internal returns(bool) {
        if(uint64(now)<FREE_START || uint64(now)>FREE_END
            ) {return false;
        } else {return true;}
    }

     
     
     
     
    function sendBreakup(address _conadd) external whenNotPaused {
        if (_ifFree()){
             
            LoveAccountBase(_conadd).breakup(msg.sender,0);}
        else{
            uint _balance = _conadd.balance;
            uint _fee = _calculate(_balance, BU_FEE_VERSE);
             
            LoveAccountBase(_conadd).breakup(msg.sender,_fee);}
        Breakup(now);
     }

     
     
     
     
    function sendMileStone(
        address _conadd, uint _time, 
        uint _choice) external payable whenNotPaused {
        require(msg.value >= STONE_FEE);
        uint8 _choice8 = uint8(_choice);
        require(_choice8>2 && _choice8<=18);
         
        LoveAccountBase(_conadd).mileStone(msg.sender, uint64(_time), _choice8);
        StoneLog(_time, _choice8);
    }
    
     
     
    function sendDiary(address _conadd, bytes _diary) external whenNotPaused{
        LoveAccountBase(_conadd).Diary(msg.sender, _diary);
        DiaryLog(now, _diary);
    }
    
     
     
     
    function bankWithdraw(address _conadd, uint _amount) external whenNotPaused{
         
        require(!pendingList[_conadd].pending || now>pendingList[_conadd].endTime);
        uint256 _fee;
        uint256 _amount256 = uint256(_amount); 
        require(_amount256==_amount);

         
        if (_ifFree()){_fee=0;}else{_fee=_calculate(_amount, WD_FEE_VERSE);}

         
        LoveAccountBase _conA = LoveAccountBase(_conadd);
        _conA.withdraw(_amount, msg.sender, _fee);

         
        uint64 _end = uint64(now)+CONFIRM_LIMIT;
        pendingList[_conadd] = pending({
                    pending:true,
                    withdrawer:msg.sender,
                    amount: _amount256,
                    fee:_fee,
                    endTime: _end});
        Withdraw(_amount256, _end);
    }

     
     
     
    function bankConfirm(address _conadd, uint _amount) external whenNotPaused{
         
        uint256 _amount256 = uint256(_amount); 
        require(_amount256==_amount);
        require(pendingList[_conadd].pending && now<pendingList[_conadd].endTime);
        require(pendingList[_conadd].withdrawer != msg.sender);
        require(pendingList[_conadd].amount == _amount);

         
        LoveAccountBase(_conadd).withdrawConfirm(_amount, msg.sender);

         
        delete pendingList[_conadd];
        WithdrawConfirm(_amount, now);
    }
}

 
 
 
 
contract LovePromo is Bank{

     
     
     
    function setFreeTime(uint _start, uint _end) external onlyCOO {
        require(_end>=_start && _start>uint64(now));
        FREE_START = uint64(_start);
        FREE_END = uint64(_end);
    }


     
     
     
     
     
     
     

    function setFee(
        uint _withdrawFee, 
        uint _breakupFee, 
        uint _stone, 
        uint _open) external onlyCEO {

         
        require(_withdrawFee>=100);
         
        require(_breakupFee>=50);

        WD_FEE_VERSE = uint64(_withdrawFee);
        BU_FEE_VERSE = uint64(_breakupFee);
        STONE_FEE = _stone;
        OPEN_FEE = _open;
    }

     
     
    function setConfirm(uint _newlimit) external onlyCEO {
        CONFIRM_LIMIT = uint32(_newlimit);
    }

     
    function getFreeTime() external view onlyCLevel returns(uint64 _start, uint64 _end){
        _start = uint64(FREE_START);
        _end = uint64(FREE_END);
    }
    
     
    function getFee() external view onlyCLevel returns(
        uint64 _withdrawFee, 
        uint64 _breakupFee, 
        uint _stone, 
        uint _open){

        _withdrawFee = WD_FEE_VERSE;
        _breakupFee = BU_FEE_VERSE;
        _stone = STONE_FEE;
        _open = OPEN_FEE;
    }
}

 
 
 
 
 
contract BankCore is LovePromo {

     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     
     


     
    address public newContractAddress;

     
    event DepositBank(address _sender, uint _value);

    function BankCore() public {
         
        paused = true;
         
        ceoAddress = msg.sender;
         
        cooAddress = msg.sender;
         
        cfoAddress = msg.sender;
    }

     
     
     
     
     
     
     
    function setNewAddress(address _v2Address) external onlyCEO whenPaused {
        newContractAddress = _v2Address;
        ContractUpgrade(_v2Address);
    }

     
     
     
    function unpause() public onlyCEO whenPaused {
        require(newContractAddress == address(0));
         
        super.unpause();
    }
    
     
     
     
    function changeBank(address _conadd, address newBank) external whenPaused onlyCEO{
        require(newBank != address(0));
        LoveAccountBase(_conadd).changeBankAccount(newBank);
    }

     
    function withdrawBalance() external onlyCFO {
         
        if (this.balance > 0) {
            cfoAddress.transfer(this.balance);
        }
    }
    
     
    function getContract(address _add1, address _add2) external view returns(address){
        bytes16 _sig = bytes16(keccak256(_add1))^bytes16(keccak256(_add2));
        return sig_to_add[_sig];
    }
    
     
    function receiveFee() external payable{}
    
     
    function() external payable onlyCLevel {
        require(msg.value>0);
        DepositBank(msg.sender, msg.value);
    }
}
 

pragma solidity 0.4.23;


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


contract ERC20Basic {
    function totalSupply() public view returns (uint256);
    function balanceOf(address who) public view returns (uint256);
    function transfer(address to, uint256 value) public returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}


contract ERC20 is ERC20Basic {
    function allowance(address owner, address spender) public view returns (uint256);
    function transferFrom(address from, address to, uint256 value) public returns (bool);
    function approve(address spender, uint256 value) public returns (bool);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


 
 
 

contract Escrow{

    using SafeMath for uint;
    enum JobStatus { Open, inProgress, Completed, Cancelled }

    struct Job{
        string description;                
         
        address manager;                   
        uint salaryDeposited;              
        address worker;                    
        JobStatus status;                  
        uint noOfTotalPayments;            
        uint noOfPaymentsMade;             
        uint paymentAvailableForWorker;    
        uint totalPaidToWorker;            
        address evaluator;                 
        bool proofOfLastWorkVerified;      
        uint sponsoredTokens;              
        mapping(address => uint) sponsors;  
        address[] sponsorList;              
        uint sponsorsCount;                 
    }

    Job[] public Jobs;                     


    mapping(address => uint[]) public JobsByManager;         
    mapping(address => uint[]) public JobsByWorker;          


    ERC20 public DAI;

    uint public jobCount = 0;      

    address public arbitrator;      

    constructor(address _DAI, address _arbitrator) public{
        DAI = ERC20(_DAI);
        arbitrator = _arbitrator;
    }


    modifier onlyArbitrator{
        require(msg.sender == arbitrator);
        _;
    }

    event JobCreated(address manager, uint salary, uint noOfTotalPayments, uint JobID, string description, address _evaluator);

     
     
     
     
    function createJob(string _description, uint _salary, uint _noOfTotalPayments, address _evaluator) public {
        require(_salary > 0);
        require(_noOfTotalPayments > 0);

        address[] memory empty;
        uint finalSalary = _salary.sub(_salary.mul(1).div(10));

        Job memory newJob = Job(_description, msg.sender, finalSalary, 0x0, JobStatus.Open, _noOfTotalPayments, 0, 0, 0, _evaluator, false, 0, empty, 0);
        Jobs.push(newJob);
        JobsByManager[msg.sender].push(jobCount);

        require(DAI.allowance(msg.sender, address(this)) >= _salary);

        emit JobCreated(msg.sender, finalSalary, _noOfTotalPayments, jobCount, _description, _evaluator);
        jobCount++;

        DAI.transferFrom(msg.sender, address(this), _salary);

    }


    event JobClaimed(address worker, uint JobID);

     
     
     
    function claimJob(uint _JobID) public {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];

        require(msg.sender != job.manager);
        require(msg.sender != job.evaluator);

        require(job.status == JobStatus.Open);

        job.worker = msg.sender;
        job.status = JobStatus.inProgress;

        JobsByWorker[msg.sender].push(_JobID);
        emit JobClaimed(msg.sender, _JobID);


    }


    event EvaluatorSet(uint JobID, address evaluator);

     
     
    function setEvaluator(uint _JobID) public {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];

        require(msg.sender != job.manager);
        require(msg.sender != job.worker);

        job.evaluator = msg.sender;
        emit EvaluatorSet(_JobID, msg.sender);

    }


    event JobCancelled(uint JobID);

     
     
     
    function cancelJob(uint _JobID) public {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];

        if(msg.sender != arbitrator){
            require(job.manager == msg.sender);
            require(job.worker == 0x0);
            require(job.status == JobStatus.Open);
        }

        job.status = JobStatus.Cancelled;
        uint returnAmount = job.salaryDeposited;

        emit JobCancelled(_JobID);
        DAI.transfer(job.manager, returnAmount);
    }


    event PaymentClaimed(address worker, uint amount, uint JobID);

     
     
     
    function claimPayment(uint _JobID) public {
        require(_JobID >= 0);
        Job storage job = Jobs[_JobID];

        require(job.worker == msg.sender);
        require(job.noOfPaymentsMade > 0);

        uint payment = job.paymentAvailableForWorker;
        require(payment > 0);

        job.paymentAvailableForWorker = 0;
        job.totalPaidToWorker = job.totalPaidToWorker + payment;
        emit PaymentClaimed(msg.sender, payment, _JobID);
        DAI.transfer(msg.sender, payment);

    }


    event PaymentApproved(address manager, uint JobID, uint amount);

     
     
    function approvePayment(uint _JobID) public {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];

        if(msg.sender != arbitrator){
            require(job.manager == msg.sender);
            require(job.proofOfLastWorkVerified == true);
        }
        require(job.noOfTotalPayments > job.noOfPaymentsMade);

        uint currentPayment = job.salaryDeposited.div(job.noOfTotalPayments);

        job.paymentAvailableForWorker = job.paymentAvailableForWorker + currentPayment;
        job.salaryDeposited = job.salaryDeposited - currentPayment;
        job.noOfPaymentsMade++;

        if(job.noOfTotalPayments == job.noOfPaymentsMade){
            job.status = JobStatus.Completed;
        }

        emit PaymentApproved(msg.sender, _JobID, currentPayment);

    }


    event EvaluatorPaid(address manager, address evaluator, uint JobID, uint payment);

     
     
     
     
    function payToEvaluator(uint _JobID, uint _payment) public {
        require(_JobID >= 0);
        require(_payment > 0);

        Job storage job = Jobs[_JobID];
        require(msg.sender == job.manager);

        address evaluator = job.evaluator;

        require(DAI.allowance(job.manager, address(this)) >= _payment);

        emit EvaluatorPaid(msg.sender, evaluator, _JobID, _payment);
        DAI.transferFrom(job.manager, evaluator, _payment);


    }


    event ProofOfWorkConfirmed(uint JobID, address evaluator, bool proofVerified);

     
     
    function confirmProofOfWork(uint _JobID) public {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];
        require(msg.sender == job.evaluator);

        job.proofOfLastWorkVerified = true;

        emit ProofOfWorkConfirmed(_JobID, job.evaluator, true);

    }

    event ProofOfWorkProvided(uint JobID, address worker, bool proofProvided);

     
     
    function provideProofOfWork(uint _JobID) public {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];
        require(msg.sender == job.worker);

        job.proofOfLastWorkVerified = false;
        emit ProofOfWorkProvided(_JobID, msg.sender, true);

    }


    event TipMade(address from, address to, uint amount);

     
     
     
     
    function tip(address _to, uint _amount) public {
        require(_to != 0x0);
        require(_amount > 0);
        require(DAI.allowance(msg.sender, address(this)) >= _amount);

        emit TipMade(msg.sender, _to, _amount);
        DAI.transferFrom(msg.sender, _to, _amount);
    }


    event DAISponsored(uint JobID, uint amount, address sponsor);

     
     
     
     
    function sponsorDAI(uint _JobID, uint _amount) public {
        require(_JobID >= 0);
        require(_amount > 0);

        Job storage job = Jobs[_JobID];
        require(job.status == JobStatus.inProgress);

        if(job.sponsors[msg.sender] == 0){
            job.sponsorList.push(msg.sender);
        }

        job.sponsors[msg.sender] = job.sponsors[msg.sender] + _amount;
        job.sponsoredTokens = job.sponsoredTokens + _amount;

        job.paymentAvailableForWorker = job.paymentAvailableForWorker + _amount;


        job.sponsorsCount = job.sponsorsCount + 1;
        emit DAISponsored(_JobID, _amount, msg.sender);

        require(DAI.allowance(msg.sender, address(this)) >= _amount);
        DAI.transferFrom(msg.sender, address(this), _amount);
    }

    event DAIWithdrawn(address receiver,uint amount);

     
     
     
     
    function withdrawDAI(address _receiver, uint _amount) public onlyArbitrator {
        require(_receiver != 0x0);
        require(_amount > 0);

        require(DAI.balanceOf(address(this)) >= _amount);

        DAI.transfer(_receiver, _amount);
        emit DAIWithdrawn(_receiver, _amount);
    }


     
     
     
    function get_Sponsored_Amount_in_Job_By_Address(uint _JobID, address _sponsor) public view returns (uint) {
        require(_JobID >= 0);
        require(_sponsor != 0x0);

        Job storage job = Jobs[_JobID];

        return job.sponsors[_sponsor];
    }


     
     
    function get_Sponsors_list_by_Job(uint _JobID) public view returns (address[] list) {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];

        list = new address[](job.sponsorsCount);

        list = job.sponsorList;
    }


    function getJob(uint _JobID) public view returns ( string _description, address _manager, uint _salaryDeposited, address _worker, uint _status, uint _noOfTotalPayments, uint _noOfPaymentsMade, uint _paymentAvailableForWorker, uint _totalPaidToWorker, address _evaluator, bool _proofOfLastWorkVerified, uint _sponsoredTokens, uint _sponsorsCount) {
        require(_JobID >= 0);

        Job storage job = Jobs[_JobID];
        _description = job.description;
        _manager = job.manager;
        _salaryDeposited = job.salaryDeposited;
        _worker = job.worker;
        _status = uint(job.status);
        _noOfTotalPayments = job.noOfTotalPayments;
        _noOfPaymentsMade = job.noOfPaymentsMade;
        _paymentAvailableForWorker = job.paymentAvailableForWorker;
        _totalPaidToWorker = job.totalPaidToWorker;
        _evaluator = job.evaluator;
        _proofOfLastWorkVerified = job.proofOfLastWorkVerified;
        _sponsoredTokens = job.sponsoredTokens;
        _sponsorsCount = job.sponsorsCount;
    }

}
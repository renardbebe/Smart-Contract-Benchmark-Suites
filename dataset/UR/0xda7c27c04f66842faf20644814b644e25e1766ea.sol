 

pragma solidity ^0.4.11;

contract Ownable {
   
  address public owner;

  function Ownable() {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    if (msg.sender != owner)
      throw;
    _;
  }

  function transferOwnership(address newOwner) onlyOwner {
    if (newOwner != address(0))
      owner = newOwner;
  }
}


contract Destructable is Ownable {
  function selfdestruct() external onlyOwner {
     
    selfdestruct(owner);
  }
}


contract Math {
   
  uint constant public FP_SCALE = 10000;

   
  function divRound(uint v, uint d) internal constant returns(uint) {
     
    return (v + (d/2)) / d;
  }

  function absDiff(uint v1, uint v2) public constant returns(uint) {
    return v1 > v2 ? v1 - v2 : v2 - v1;
  }

  function safeMul(uint a, uint b) public constant returns (uint) {
    uint c = a * b;
    if (a == 0 || c / a == b)
      return c;
    else
      throw;
  }

  function safeAdd(uint a, uint b) internal constant returns (uint) {
    uint c = a + b;
    if (!(c>=a && c>=b))
      throw;
    return c;
  }
}


contract TimeSource {
  uint32 private mockNow;

  function currentTime() public constant returns (uint32) {
     
    if (block.timestamp > 0xFFFFFFFF)
      throw;
    return mockNow > 0 ? mockNow : uint32(block.timestamp);
  }

  function mockTime(uint32 t) public {
     
    if (block.number > 3316029)
      throw;
    mockNow = t;
  }
}


contract BaseOptionsConverter {

   
   
  modifier onlyESOP() {
    if (msg.sender != getESOP())
      throw;
    _;
  }

   
  function getESOP() public constant returns (address);
   
  function getExercisePeriodDeadline() public constant returns (uint32);

   
   
  function exerciseOptions(address employee, uint poolOptions, uint extraOptions, uint bonusOptions,
    bool agreeToAcceleratedVestingBonusConditions) onlyESOP public;
}

contract ESOPTypes {
   
  enum EmployeeState { NotSet, WaitingForSignature, Employed, Terminated, OptionsExercised }
   
   
  struct Employee {
       
      uint32 issueDate;
       
      uint32 timeToSign;
       
      uint32 terminatedAt;
       
       
      uint32 fadeoutStarts;
       
      uint32 poolOptions;
       
      uint32 extraOptions;
       
      uint32 suspendedAt;
       
      EmployeeState state;
       
      uint16 idx;
       
       
  }

  function serializeEmployee(Employee memory employee)
    internal
    constant
    returns(uint[9] emp)
  {
       
       
      assembly {
         
         
         
        emp := employee
      }
  }

  function deserializeEmployee(uint[9] serializedEmployee)
    internal
    constant
    returns (Employee memory emp)
  {
      assembly { emp := serializedEmployee }
  }
}


contract CodeUpdateable is Ownable {
     
    enum CodeUpdateState { CurrentCode, OngoingUpdate  }
    CodeUpdateState public codeUpdateState;

    modifier isCurrentCode() {
      if (codeUpdateState != CodeUpdateState.CurrentCode)
        throw;
      _;
    }

    modifier inCodeUpdate() {
      if (codeUpdateState != CodeUpdateState.OngoingUpdate)
        throw;
      _;
    }

    function beginCodeUpdate() public onlyOwner isCurrentCode {
      codeUpdateState = CodeUpdateState.OngoingUpdate;
    }

    function cancelCodeUpdate() public onlyOwner inCodeUpdate {
      codeUpdateState = CodeUpdateState.CurrentCode;
    }

    function completeCodeUpdate() public onlyOwner inCodeUpdate {
      selfdestruct(owner);
    }
}

contract EmployeesList is ESOPTypes, Ownable, Destructable {
  event CreateEmployee(address indexed e, uint32 poolOptions, uint32 extraOptions, uint16 idx);
  event UpdateEmployee(address indexed e, uint32 poolOptions, uint32 extraOptions, uint16 idx);
  event ChangeEmployeeState(address indexed e, EmployeeState oldState, EmployeeState newState);
  event RemoveEmployee(address indexed e);
  mapping (address => Employee) employees;
   
  address[] public addresses;

  function size() external constant returns (uint16) {
    return uint16(addresses.length);
  }

  function setEmployee(address e, uint32 issueDate, uint32 timeToSign, uint32 terminatedAt, uint32 fadeoutStarts,
    uint32 poolOptions, uint32 extraOptions, uint32 suspendedAt, EmployeeState state)
    external
    onlyOwner
    returns (bool isNew)
  {
    uint16 empIdx = employees[e].idx;
    if (empIdx == 0) {
       
      uint size = addresses.length;
      if (size == 0xFFFF)
        throw;
      isNew = true;
      empIdx = uint16(size + 1);
      addresses.push(e);
      CreateEmployee(e, poolOptions, extraOptions, empIdx);
    } else {
      isNew = false;
      UpdateEmployee(e, poolOptions, extraOptions, empIdx);
    }
    employees[e] = Employee({
        issueDate: issueDate,
        timeToSign: timeToSign,
        terminatedAt: terminatedAt,
        fadeoutStarts: fadeoutStarts,
        poolOptions: poolOptions,
        extraOptions: extraOptions,
        suspendedAt: suspendedAt,
        state: state,
        idx: empIdx
      });
  }

  function changeState(address e, EmployeeState state)
    external
    onlyOwner
  {
    if (employees[e].idx == 0)
      throw;
    ChangeEmployeeState(e, employees[e].state, state);
    employees[e].state = state;
  }

  function setFadeoutStarts(address e, uint32 fadeoutStarts)
    external
    onlyOwner
  {
    if (employees[e].idx == 0)
      throw;
    UpdateEmployee(e, employees[e].poolOptions, employees[e].extraOptions, employees[e].idx);
    employees[e].fadeoutStarts = fadeoutStarts;
  }

  function removeEmployee(address e)
    external
    onlyOwner
    returns (bool)
  {
    uint16 empIdx = employees[e].idx;
    if (empIdx > 0) {
        delete employees[e];
        delete addresses[empIdx-1];
        RemoveEmployee(e);
        return true;
    }
    return false;
  }

  function terminateEmployee(address e, uint32 issueDate, uint32 terminatedAt, uint32 fadeoutStarts, EmployeeState state)
    external
    onlyOwner
  {
    if (state != EmployeeState.Terminated)
        throw;
    Employee employee = employees[e];  
    if (employee.idx == 0)
      throw;
    ChangeEmployeeState(e, employee.state, state);
    employee.state = state;
    employee.issueDate = issueDate;
    employee.terminatedAt = terminatedAt;
    employee.fadeoutStarts = fadeoutStarts;
    employee.suspendedAt = 0;
    UpdateEmployee(e, employee.poolOptions, employee.extraOptions, employee.idx);
  }

  function getEmployee(address e)
    external
    constant
    returns (uint32, uint32, uint32, uint32, uint32, uint32, uint32, EmployeeState)
  {
      Employee employee = employees[e];
      if (employee.idx == 0)
        throw;
       
      return (employee.issueDate, employee.timeToSign, employee.terminatedAt, employee.fadeoutStarts,
        employee.poolOptions, employee.extraOptions, employee.suspendedAt, employee.state);
  }

   function hasEmployee(address e)
     external
     constant
     returns (bool)
   {
       
      return employees[e].idx != 0;
    }

  function getSerializedEmployee(address e)
    external
    constant
    returns (uint[9])
  {
    Employee memory employee = employees[e];
    if (employee.idx == 0)
      throw;
    return serializeEmployee(employee);
  }
}


contract ERC20OptionsConverter is BaseOptionsConverter, TimeSource, Math {
   
  address esopAddress;
  uint32 exercisePeriodDeadline;
   
  mapping(address => uint) internal balances;
   
  uint public totalSupply;

   
  uint32 public optionsConversionDeadline;

  event Transfer(address indexed from, address indexed to, uint value);

  modifier converting() {
     
    if (currentTime() >= exercisePeriodDeadline)
      throw;
    _;
  }

  modifier converted() {
     
    if (currentTime() < optionsConversionDeadline)
      throw;
    _;
  }


  function getESOP() public constant returns (address) {
    return esopAddress;
  }

  function getExercisePeriodDeadline() public constant returns(uint32) {
    return exercisePeriodDeadline;
  }

  function exerciseOptions(address employee, uint poolOptions, uint extraOptions, uint bonusOptions,
    bool agreeToAcceleratedVestingBonusConditions)
    public
    onlyESOP
    converting
  {
     
    uint options = safeAdd(safeAdd(poolOptions, extraOptions), bonusOptions);
    totalSupply = safeAdd(totalSupply, options);
    balances[employee] += options;
    Transfer(0, employee, options);
  }

  function transfer(address _to, uint _value) converted public {
    if (balances[msg.sender] < _value)
      throw;
    balances[msg.sender] -= _value;
    balances[_to] += _value;
    Transfer(msg.sender, _to, _value);
  }

  function balanceOf(address _owner) constant public returns (uint balance) {
    return balances[_owner];
  }

  function () payable {
    throw;
  }

  function ERC20OptionsConverter(address esop, uint32 exerciseDeadline, uint32 conversionDeadline) {
    esopAddress = esop;
    exercisePeriodDeadline = exerciseDeadline;
    optionsConversionDeadline = conversionDeadline;
  }
}

contract ESOPMigration {
  modifier onlyOldESOP() {
    if (msg.sender != getOldESOP())
      throw;
    _;
  }

   
  function getOldESOP() public constant returns (address);

   
   
   
   
  function migrate(address employee, uint poolOptions, uint extraOptions) onlyOldESOP public;
}

contract ESOP is ESOPTypes, CodeUpdateable, TimeSource {
   
  event ESOPOffered(address indexed employee, address company, uint32 poolOptions, uint32 extraOptions);
  event EmployeeSignedToESOP(address indexed employee);
  event SuspendEmployee(address indexed employee, uint32 suspendedAt);
  event ContinueSuspendedEmployee(address indexed employee, uint32 continuedAt, uint32 suspendedPeriod);
  event TerminateEmployee(address indexed employee, address company, uint32 terminatedAt, TerminationType termType);
  event EmployeeOptionsExercised(address indexed employee, address exercisedFor, uint32 poolOptions, bool disableAcceleratedVesting);
  event EmployeeMigrated(address indexed employee, address migration, uint pool, uint extra);
   
  event ESOPOpened(address company);
  event OptionsConversionOffered(address company, address converter, uint32 convertedAt, uint32 exercisePeriodDeadline);
  enum ESOPState { New, Open, Conversion }
   
  enum ReturnCodes { OK, InvalidEmployeeState, TooLate, InvalidParameters, TooEarly  }
   
  event ReturnCode(ReturnCodes rc);
  enum TerminationType { Regular, BadLeaver }

   
  OptionsCalculator public optionsCalculator;
   
  uint public totalPoolOptions;
   
  bytes public ESOPLegalWrapperIPFSHash;
   
  address public companyAddress;
   
  address public rootOfTrust;
   
  uint32 constant public MINIMUM_MANUAL_SIGN_PERIOD = 2 weeks;

   
   
  uint public remainingPoolOptions;
   
  ESOPState public esopState;  
   
  EmployeesList public employees;
   
  uint public totalExtraOptions;
   
  uint32 public conversionOfferedAt;
   
  uint32 public exerciseOptionsDeadline;
   
  BaseOptionsConverter public optionsConverter;

   
  mapping (address => ESOPMigration) private migrations;

  modifier hasEmployee(address e) {
     
    if (!employees.hasEmployee(e))
      throw;
    _;
  }

  modifier onlyESOPNew() {
    if (esopState != ESOPState.New)
      throw;
    _;
  }

  modifier onlyESOPOpen() {
    if (esopState != ESOPState.Open)
      throw;
    _;
  }

  modifier onlyESOPConversion() {
    if (esopState != ESOPState.Conversion)
      throw;
    _;
  }

  modifier onlyCompany() {
    if (companyAddress != msg.sender)
      throw;
    _;
  }

  function distributeAndReturnToPool(uint distributedOptions, uint idx)
    internal
    returns (uint)
  {
     
    Employee memory emp;
    for (uint i = idx; i < employees.size(); i++) {
      address ea = employees.addresses(i);
      if (ea != 0) {  
        emp = _loademp(ea);
         
        if (emp.poolOptions > 0 && ( emp.state == EmployeeState.WaitingForSignature || emp.state == EmployeeState.Employed) ) {
          uint newoptions = optionsCalculator.calcNewEmployeePoolOptions(distributedOptions);
          emp.poolOptions += uint32(newoptions);
          distributedOptions -= uint32(newoptions);
          _saveemp(ea, emp);
        }
      }
    }
    return distributedOptions;
  }

  function removeEmployeesWithExpiredSignaturesAndReturnFadeout()
    onlyESOPOpen
    isCurrentCode
    public
  {
     
     
     
    Employee memory emp;
    uint32 ct = currentTime();
    for (uint i = 0; i < employees.size(); i++) {
      address ea = employees.addresses(i);
      if (ea != 0) {  
        var ser = employees.getSerializedEmployee(ea);
        emp = deserializeEmployee(ser);
         
        if (emp.state == EmployeeState.WaitingForSignature && ct > emp.timeToSign) {
          remainingPoolOptions += distributeAndReturnToPool(emp.poolOptions, i+1);
          totalExtraOptions -= emp.extraOptions;
           
          employees.removeEmployee(ea);
        }
         
        if (emp.state == EmployeeState.Terminated && ct > emp.fadeoutStarts) {
          var (returnedPoolOptions, returnedExtraOptions) = optionsCalculator.calculateFadeoutToPool(ct, ser);
          if (returnedPoolOptions > 0 || returnedExtraOptions > 0) {
            employees.setFadeoutStarts(ea, ct);
             
            remainingPoolOptions += returnedPoolOptions;
             
            totalExtraOptions -= returnedExtraOptions;
          }
        }
      }
    }
  }

  function openESOP(uint32 pTotalPoolOptions, bytes pESOPLegalWrapperIPFSHash)
    external
    onlyCompany
    onlyESOPNew
    isCurrentCode
    returns (ReturnCodes)
  {
     
    if (pTotalPoolOptions > 1100000 || pTotalPoolOptions < 10000) {
      return _logerror(ReturnCodes.InvalidParameters);
    }

    totalPoolOptions = pTotalPoolOptions;
    remainingPoolOptions = totalPoolOptions;
    ESOPLegalWrapperIPFSHash = pESOPLegalWrapperIPFSHash;

    esopState = ESOPState.Open;
    ESOPOpened(companyAddress);
    return ReturnCodes.OK;
  }

  function offerOptionsToEmployee(address e, uint32 issueDate, uint32 timeToSign, uint32 extraOptions, bool poolCleanup)
    external
    onlyESOPOpen
    onlyCompany
    isCurrentCode
    returns (ReturnCodes)
  {
     
    if (employees.hasEmployee(e)) {
      return _logerror(ReturnCodes.InvalidEmployeeState);
    }
    if (timeToSign < currentTime() + MINIMUM_MANUAL_SIGN_PERIOD) {
      return _logerror(ReturnCodes.TooLate);
    }
    if (poolCleanup) {
       
       
      removeEmployeesWithExpiredSignaturesAndReturnFadeout();
    }
    uint poolOptions = optionsCalculator.calcNewEmployeePoolOptions(remainingPoolOptions);
    if (poolOptions > 0xFFFFFFFF)
      throw;
    Employee memory emp = Employee({
      issueDate: issueDate, timeToSign: timeToSign, terminatedAt: 0, fadeoutStarts: 0, poolOptions: uint32(poolOptions),
      extraOptions: extraOptions, suspendedAt: 0, state: EmployeeState.WaitingForSignature, idx: 0
    });
    _saveemp(e, emp);
    remainingPoolOptions -= poolOptions;
    totalExtraOptions += extraOptions;
    ESOPOffered(e, companyAddress, uint32(poolOptions), extraOptions);
    return ReturnCodes.OK;
  }

   
   
   

  function offerOptionsToEmployeeOnlyExtra(address e, uint32 issueDate, uint32 timeToSign, uint32 extraOptions)
    external
    onlyESOPOpen
    onlyCompany
    isCurrentCode
    returns (ReturnCodes)
  {
     
    if (employees.hasEmployee(e)) {
      return _logerror(ReturnCodes.InvalidEmployeeState);
    }
    if (timeToSign < currentTime() + MINIMUM_MANUAL_SIGN_PERIOD) {
      return _logerror(ReturnCodes.TooLate);
    }
    Employee memory emp = Employee({
      issueDate: issueDate, timeToSign: timeToSign, terminatedAt: 0, fadeoutStarts: 0, poolOptions: 0,
      extraOptions: extraOptions, suspendedAt: 0, state: EmployeeState.WaitingForSignature, idx: 0
    });
    _saveemp(e, emp);
    totalExtraOptions += extraOptions;
    ESOPOffered(e, companyAddress, 0, extraOptions);
    return ReturnCodes.OK;
  }

  function increaseEmployeeExtraOptions(address e, uint32 extraOptions)
    external
    onlyESOPOpen
    onlyCompany
    isCurrentCode
    hasEmployee(e)
    returns (ReturnCodes)
  {
    Employee memory emp = _loademp(e);
    if (emp.state != EmployeeState.Employed && emp.state != EmployeeState.WaitingForSignature) {
      return _logerror(ReturnCodes.InvalidEmployeeState);
    }
    emp.extraOptions += extraOptions;
    _saveemp(e, emp);
    totalExtraOptions += extraOptions;
    ESOPOffered(e, companyAddress, 0, extraOptions);
    return ReturnCodes.OK;
  }

  function employeeSignsToESOP()
    external
    hasEmployee(msg.sender)
    onlyESOPOpen
    isCurrentCode
    returns (ReturnCodes)
  {
    Employee memory emp = _loademp(msg.sender);
    if (emp.state != EmployeeState.WaitingForSignature) {
      return _logerror(ReturnCodes.InvalidEmployeeState);
    }
    uint32 t = currentTime();
    if (t > emp.timeToSign) {
      remainingPoolOptions += distributeAndReturnToPool(emp.poolOptions, emp.idx);
      totalExtraOptions -= emp.extraOptions;
      employees.removeEmployee(msg.sender);
      return _logerror(ReturnCodes.TooLate);
    }
    employees.changeState(msg.sender, EmployeeState.Employed);
    EmployeeSignedToESOP(msg.sender);
    return ReturnCodes.OK;
  }

  function toggleEmployeeSuspension(address e, uint32 toggledAt)
    external
    onlyESOPOpen
    onlyCompany
    hasEmployee(e)
    isCurrentCode
    returns (ReturnCodes)
  {
    Employee memory emp = _loademp(e);
    if (emp.state != EmployeeState.Employed) {
      return _logerror(ReturnCodes.InvalidEmployeeState);
    }
    if (emp.suspendedAt == 0) {
       
      emp.suspendedAt = toggledAt;
      SuspendEmployee(e, toggledAt);
    } else {
      if (emp.suspendedAt > toggledAt) {
        return _logerror(ReturnCodes.TooLate);
      }
      uint32 suspendedPeriod = toggledAt - emp.suspendedAt;
       
      emp.issueDate += suspendedPeriod;
      emp.suspendedAt = 0;
      ContinueSuspendedEmployee(e, toggledAt, suspendedPeriod);
    }
    _saveemp(e, emp);
    return ReturnCodes.OK;
  }

  function terminateEmployee(address e, uint32 terminatedAt, uint8 terminationType)
    external
    onlyESOPOpen
    onlyCompany
    hasEmployee(e)
    isCurrentCode
    returns (ReturnCodes)
  {
     
    TerminationType termType = TerminationType(terminationType);
    Employee memory emp = _loademp(e);
     
    if (terminatedAt < emp.issueDate) {
      return _logerror(ReturnCodes.InvalidParameters);
    }
    if (emp.state == EmployeeState.WaitingForSignature)
      termType = TerminationType.BadLeaver;
    else if (emp.state != EmployeeState.Employed) {
      return _logerror(ReturnCodes.InvalidEmployeeState);
    }
     
    uint returnedOptions;
    uint returnedExtraOptions;
    if (termType == TerminationType.Regular) {
       
      if (emp.suspendedAt > 0 && emp.suspendedAt < terminatedAt)
        emp.issueDate += terminatedAt - emp.suspendedAt;
       
      returnedOptions = emp.poolOptions - optionsCalculator.calculateVestedOptions(terminatedAt, emp.issueDate, emp.poolOptions);
      returnedExtraOptions = emp.extraOptions - optionsCalculator.calculateVestedOptions(terminatedAt, emp.issueDate, emp.extraOptions);
      employees.terminateEmployee(e, emp.issueDate, terminatedAt, terminatedAt, EmployeeState.Terminated);
    } else if (termType == TerminationType.BadLeaver) {
       
      returnedOptions = emp.poolOptions;
      returnedExtraOptions = emp.extraOptions;
      employees.removeEmployee(e);
    }
    remainingPoolOptions += distributeAndReturnToPool(returnedOptions, emp.idx);
    totalExtraOptions -= returnedExtraOptions;
    TerminateEmployee(e, companyAddress, terminatedAt, termType);
    return ReturnCodes.OK;
  }

  function offerOptionsConversion(BaseOptionsConverter converter)
    external
    onlyESOPOpen
    onlyCompany
    isCurrentCode
    returns (ReturnCodes)
  {
    uint32 offerMadeAt = currentTime();
    if (converter.getExercisePeriodDeadline() - offerMadeAt < MINIMUM_MANUAL_SIGN_PERIOD) {
      return _logerror(ReturnCodes.TooLate);
    }
     
    if (converter.getESOP() != address(this)) {
      return _logerror(ReturnCodes.InvalidParameters);
    }
     
    removeEmployeesWithExpiredSignaturesAndReturnFadeout();
     
    conversionOfferedAt = offerMadeAt;
    exerciseOptionsDeadline = converter.getExercisePeriodDeadline();
    optionsConverter = converter;
     
    esopState = ESOPState.Conversion;
    OptionsConversionOffered(companyAddress, address(converter), offerMadeAt, exerciseOptionsDeadline);
    return ReturnCodes.OK;
  }

  function exerciseOptionsInternal(uint32 calcAtTime, address employee, address exerciseFor,
    bool disableAcceleratedVesting)
    internal
    returns (ReturnCodes)
  {
    Employee memory emp = _loademp(employee);
    if (emp.state == EmployeeState.OptionsExercised) {
      return _logerror(ReturnCodes.InvalidEmployeeState);
    }
     
    if (exerciseFor != address(0)) {
      var (pool, extra, bonus) = optionsCalculator.calculateOptionsComponents(serializeEmployee(emp),
        calcAtTime, conversionOfferedAt, disableAcceleratedVesting);
      }
     
    employees.changeState(employee, EmployeeState.OptionsExercised);
     
    optionsConverter.exerciseOptions(exerciseFor, pool, extra, bonus, !disableAcceleratedVesting);
    EmployeeOptionsExercised(employee, exerciseFor, uint32(pool + extra + bonus), !disableAcceleratedVesting);
    return ReturnCodes.OK;
  }

  function employeeExerciseOptions(bool agreeToAcceleratedVestingBonusConditions)
    external
    onlyESOPConversion
    hasEmployee(msg.sender)
    isCurrentCode
    returns (ReturnCodes)
  {
    uint32 ct = currentTime();
    if (ct > exerciseOptionsDeadline) {
      return _logerror(ReturnCodes.TooLate);
    }
    return exerciseOptionsInternal(ct, msg.sender, msg.sender, !agreeToAcceleratedVestingBonusConditions);
  }

  function employeeDenyExerciseOptions()
    external
    onlyESOPConversion
    hasEmployee(msg.sender)
    isCurrentCode
    returns (ReturnCodes)
  {
    uint32 ct = currentTime();
    if (ct > exerciseOptionsDeadline) {
      return _logerror(ReturnCodes.TooLate);
    }
     
    return exerciseOptionsInternal(ct, msg.sender, address(0), true);
  }

  function exerciseExpiredEmployeeOptions(address e, bool disableAcceleratedVesting)
    external
    onlyESOPConversion
    onlyCompany
    hasEmployee(e)
    isCurrentCode
  returns (ReturnCodes)
  {
     
    uint32 ct = currentTime();
    if (ct <= exerciseOptionsDeadline) {
      return _logerror(ReturnCodes.TooEarly);
    }
    return exerciseOptionsInternal(ct, e, companyAddress, disableAcceleratedVesting);
  }

  function allowEmployeeMigration(address employee, ESOPMigration migration)
    external
    onlyESOPOpen
    hasEmployee(employee)
    onlyCompany
    isCurrentCode
    returns (ReturnCodes)
  {
    if (address(migration) == 0)
      throw;
     
    Employee memory emp = _loademp(employee);
    if (emp.state != EmployeeState.Employed && emp.state != EmployeeState.Terminated) {
      return _logerror(ReturnCodes.InvalidEmployeeState);
    }
    migrations[employee] = migration;  
    return ReturnCodes.OK;
  }

  function employeeMigratesToNewESOP(ESOPMigration migration)
    external
    onlyESOPOpen
    hasEmployee(msg.sender)
    isCurrentCode
    returns (ReturnCodes)
  {
     
     
    if (address(migration) == 0 || migrations[msg.sender] != migration)
      throw;
     
    removeEmployeesWithExpiredSignaturesAndReturnFadeout();
     
    Employee memory emp = _loademp(msg.sender);
    if (emp.state != EmployeeState.Employed && emp.state != EmployeeState.Terminated) {
      return _logerror(ReturnCodes.InvalidEmployeeState);
    }
     
    var (pool, extra, _) = optionsCalculator.calculateOptionsComponents(serializeEmployee(emp), currentTime(), 0, false);
    delete migrations[msg.sender];
     
    migration.migrate(msg.sender, pool, extra);
     
    totalExtraOptions -= emp.state == EmployeeState.Employed ? emp.extraOptions : extra;
     
     
     
    totalPoolOptions -= emp.state == EmployeeState.Employed ? emp.poolOptions : pool;
     
    employees.removeEmployee(msg.sender);
    EmployeeMigrated(msg.sender, migration, pool, extra);
    return ReturnCodes.OK;
  }

  function calcEffectiveOptionsForEmployee(address e, uint32 calcAtTime)
    public
    constant
    hasEmployee(e)
    isCurrentCode
    returns (uint)
  {
    return optionsCalculator.calculateOptions(employees.getSerializedEmployee(e), calcAtTime, conversionOfferedAt, false);
  }

  function _logerror(ReturnCodes c) private returns (ReturnCodes) {
    ReturnCode(c);
    return c;
  }

  function _loademp(address e) private constant returns (Employee memory) {
    return deserializeEmployee(employees.getSerializedEmployee(e));
  }

  function _saveemp(address e, Employee memory emp) private {
    employees.setEmployee(e, emp.issueDate, emp.timeToSign, emp.terminatedAt, emp.fadeoutStarts, emp.poolOptions,
      emp.extraOptions, emp.suspendedAt, emp.state);
  }

  function completeCodeUpdate() public onlyOwner inCodeUpdate {
    employees.transferOwnership(msg.sender);
    CodeUpdateable.completeCodeUpdate();
  }

  function()
      payable
  {
      throw;
  }

  function ESOP(address company, address pRootOfTrust, OptionsCalculator pOptionsCalculator, EmployeesList pEmployeesList) {
     
    companyAddress = company;
    rootOfTrust = pRootOfTrust;
    employees = pEmployeesList;
    optionsCalculator = pOptionsCalculator;
  }
}




contract OptionsCalculator is Ownable, Destructable, Math, ESOPTypes {
   
  uint public cliffPeriod;
   
  uint public vestingPeriod;
   
  uint public maxFadeoutPromille;
   
  function residualAmountPromille() public constant returns(uint) { return FP_SCALE - maxFadeoutPromille; }
   
  uint public bonusOptionsPromille;
   
  uint public newEmployeePoolPromille;
   
  uint public optionsPerShare;
   
  uint constant public STRIKE_PRICE = 1;
   
  address public companyAddress;
   
  function hasParameters() public constant returns(bool) { return optionsPerShare > 0; }

  modifier onlyCompany() {
    if (companyAddress != msg.sender)
      throw;
    _;
  }

  function calcNewEmployeePoolOptions(uint remainingPoolOptions)
    public
    constant
    returns (uint)
  {
    return divRound(remainingPoolOptions * newEmployeePoolPromille, FP_SCALE);
  }

  function calculateVestedOptions(uint t, uint vestingStarts, uint options)
    public
    constant
    returns (uint)
  {
    if (t <= vestingStarts)
      return 0;
     
    uint effectiveTime = t - vestingStarts;
     
    if (effectiveTime < cliffPeriod)
      return 0;
    else
      return  effectiveTime < vestingPeriod ? divRound(options * effectiveTime, vestingPeriod) : options;
  }

  function applyFadeoutToOptions(uint32 t, uint32 issueDate, uint32 terminatedAt, uint options, uint vestedOptions)
    public
    constant
    returns (uint)
  {
    if (t < terminatedAt)
      return vestedOptions;
    uint timefromTermination = t - terminatedAt;
     
    uint employmentPeriod = terminatedAt - issueDate;
     
    uint minFadeValue = divRound(options * (FP_SCALE - maxFadeoutPromille), FP_SCALE);
     
    if (minFadeValue >= vestedOptions)
      return vestedOptions;
    return timefromTermination > employmentPeriod ?
      minFadeValue  :
      (minFadeValue + divRound((vestedOptions - minFadeValue) * (employmentPeriod - timefromTermination), employmentPeriod));
  }

  function calculateOptionsComponents(uint[9] employee, uint32 calcAtTime, uint32 conversionOfferedAt,
    bool disableAcceleratedVesting)
    public
    constant
    returns (uint, uint, uint)
  {
     
    Employee memory emp = deserializeEmployee(employee);
     
    if (emp.state == EmployeeState.OptionsExercised || emp.state == EmployeeState.WaitingForSignature)
      return (0,0,0);
     
    bool isESOPConverted = conversionOfferedAt > 0 && calcAtTime >= conversionOfferedAt;  
    uint issuedOptions = emp.poolOptions + emp.extraOptions;
     
    if (issuedOptions == 0)
      return (0,0,0);
     
    if (calcAtTime < emp.terminatedAt && emp.terminatedAt > 0)
      emp.state = EmployeeState.Employed;
    uint vestedOptions = issuedOptions;
    bool accelerateVesting = isESOPConverted && emp.state == EmployeeState.Employed && !disableAcceleratedVesting;
    if (!accelerateVesting) {
       
      uint32 calcVestingAt = emp.state ==
         
        EmployeeState.Terminated ? emp.terminatedAt :
         
        (emp.suspendedAt > 0 && emp.suspendedAt < calcAtTime ? emp.suspendedAt :
         
        conversionOfferedAt > 0 ? conversionOfferedAt :
         
        calcAtTime);
      vestedOptions = calculateVestedOptions(calcVestingAt, emp.issueDate, issuedOptions);
    }
     
    if (emp.state == EmployeeState.Terminated) {
       
      vestedOptions = applyFadeoutToOptions(isESOPConverted ? conversionOfferedAt : calcAtTime,
        emp.issueDate, emp.terminatedAt, issuedOptions, vestedOptions);
    }
    var (vestedPoolOptions, vestedExtraOptions) = extractVestedOptionsComponents(emp.poolOptions, emp.extraOptions, vestedOptions);
     
    return  (vestedPoolOptions, vestedExtraOptions,
      accelerateVesting ? divRound(vestedPoolOptions*bonusOptionsPromille, FP_SCALE) : 0 );
  }

  function calculateOptions(uint[9] employee, uint32 calcAtTime, uint32 conversionOfferedAt, bool disableAcceleratedVesting)
    public
    constant
    returns (uint)
  {
    var (vestedPoolOptions, vestedExtraOptions, bonus) = calculateOptionsComponents(employee, calcAtTime,
      conversionOfferedAt, disableAcceleratedVesting);
    return vestedPoolOptions + vestedExtraOptions + bonus;
  }

  function extractVestedOptionsComponents(uint issuedPoolOptions, uint issuedExtraOptions, uint vestedOptions)
    public
    constant
    returns (uint, uint)
  {
     
    if (issuedExtraOptions == 0)
      return (vestedOptions, 0);
    uint poolOptions = divRound(issuedPoolOptions*vestedOptions, issuedPoolOptions + issuedExtraOptions);
    return (poolOptions, vestedOptions - poolOptions);
  }

  function calculateFadeoutToPool(uint32 t, uint[9] employee)
    public
    constant
    returns (uint, uint)
  {
    Employee memory emp = deserializeEmployee(employee);

    uint vestedOptions = calculateVestedOptions(emp.terminatedAt, emp.issueDate, emp.poolOptions);
    uint returnedPoolOptions = applyFadeoutToOptions(emp.fadeoutStarts, emp.issueDate, emp.terminatedAt, emp.poolOptions, vestedOptions) -
      applyFadeoutToOptions(t, emp.issueDate, emp.terminatedAt, emp.poolOptions, vestedOptions);
    uint vestedExtraOptions = calculateVestedOptions(emp.terminatedAt, emp.issueDate, emp.extraOptions);
    uint returnedExtraOptions = applyFadeoutToOptions(emp.fadeoutStarts, emp.issueDate, emp.terminatedAt, emp.extraOptions, vestedExtraOptions) -
      applyFadeoutToOptions(t, emp.issueDate, emp.terminatedAt, emp.extraOptions, vestedExtraOptions);

    return (returnedPoolOptions, returnedExtraOptions);
  }

  function simulateOptions(uint32 issueDate, uint32 terminatedAt, uint32 poolOptions,
    uint32 extraOptions, uint32 suspendedAt, uint8 employeeState, uint32 calcAtTime)
    public
    constant
    returns (uint)
  {
    Employee memory emp = Employee({issueDate: issueDate, terminatedAt: terminatedAt,
      poolOptions: poolOptions, extraOptions: extraOptions, state: EmployeeState(employeeState),
      timeToSign: issueDate+2 weeks, fadeoutStarts: terminatedAt, suspendedAt: suspendedAt,
      idx:1});
    return calculateOptions(serializeEmployee(emp), calcAtTime, 0, false);
  }

  function setParameters(uint32 pCliffPeriod, uint32 pVestingPeriod, uint32 pResidualAmountPromille,
    uint32 pBonusOptionsPromille, uint32 pNewEmployeePoolPromille, uint32 pOptionsPerShare)
    external
    onlyCompany
  {
    if (pResidualAmountPromille > FP_SCALE || pBonusOptionsPromille > FP_SCALE || pNewEmployeePoolPromille > FP_SCALE
     || pOptionsPerShare == 0)
      throw;
    if (pCliffPeriod > pVestingPeriod)
      throw;
     
    if (hasParameters())
      throw;
    cliffPeriod = pCliffPeriod;
    vestingPeriod = pVestingPeriod;
    maxFadeoutPromille = FP_SCALE - pResidualAmountPromille;
    bonusOptionsPromille = pBonusOptionsPromille;
    newEmployeePoolPromille = pNewEmployeePoolPromille;
    optionsPerShare = pOptionsPerShare;
  }

  function OptionsCalculator(address pCompanyAddress) {
    companyAddress = pCompanyAddress;
  }
}

contract ProceedsOptionsConverter is Ownable, ERC20OptionsConverter {
  mapping (address => uint) internal withdrawals;
  uint[] internal payouts;

  function makePayout() converted payable onlyOwner public {
     
    if (msg.value < 1 ether)
      throw;
    payouts.push(msg.value);
  }

  function withdraw() converted public returns (uint) {
     
    uint balance = balanceOf(msg.sender);
    if (balance == 0)
      return 0;
    uint paymentId = withdrawals[msg.sender];
     
    if (paymentId == payouts.length)
      return 0;
    uint payout = 0;
    for (uint i = paymentId; i<payouts.length; i++) {
       
       
       
       
      uint thisPayout = divRound(safeMul(payouts[i], balance), totalSupply);
      payout += thisPayout;
    }
     
    withdrawals[msg.sender] = payouts.length;
    if (payout > 0) {
       
       
       
      if ( absDiff(this.balance, payout) < 1000 wei )
        payout = this.balance;  
       
       
      if (!msg.sender.send(payout))
        throw;
    }
    return payout;
  }

  function transfer(address _to, uint _value) public converted {
     
     
     
     
    if (withdrawals[_to] > 0 || withdrawals[msg.sender] > 0)
      throw;
    ERC20OptionsConverter.transfer(_to, _value);
  }

  function ProceedsOptionsConverter(address esop, uint32 exerciseDeadline, uint32 conversionDeadline)
    ERC20OptionsConverter(esop, exerciseDeadline, conversionDeadline)
  {
  }
}

contract RoT is Ownable {
    address public ESOPAddress;
    event ESOPAndCompanySet(address ESOPAddress, address companyAddress);

    function setESOP(address ESOP, address company) public onlyOwner {
       
       
      ESOPAddress = ESOP;
      transferOwnership(company);
      ESOPAndCompanySet(ESOP, company);
    }

    function killOnUnsupportedFork() public onlyOwner {
       
      delete ESOPAddress;
      selfdestruct(owner);
    }
}
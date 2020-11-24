 

pragma solidity ^0.5.0;

contract MesDataPlatform {

     
    address public owner = msg.sender;
    
     
    struct Survey {
        uint256 studyId;
        uint256 surveyId;
        string surveyName;
        uint256 surveyJsonHash;  
        bool isDeleted;
        uint256[] exportedHash;  
        mapping(address => uint256) answersJsonHash;  
    }
    
     
    struct Consent {
        uint256 signedByParticipantAt;  
        uint256 signedByStudyCreatorAt;  
        uint256 signedByStudySupervisorAt;  
    }
    
     
    struct Study {
        uint256 studyId;
        string studyName;
        address creatorId;
        address supervisorId;
        bool isDeleted;
        address[] participants;  
        uint256[] surveyIds;  
        mapping(uint256 => Survey) surveys;  
        mapping(address => Consent) consents;  
    }
    
    uint256[] public studiesIDs;  
    mapping(uint256 => Study) public studies;  
    
    
    constructor() public
    {
        owner = msg.sender;
    }
    
     
    function addStudy(uint256 studyId, string memory studyName, address supervisorId) public payable 
    {
        require(
            studies[studyId].studyId == 0,
            "Study already exists"
        );
        Study memory studyObject = Study(studyId, studyName, msg.sender, supervisorId, false, new address[](0), new uint256[](0));
        studies[studyId] = studyObject;
        studiesIDs.push(studyId);
    }
    
     
    function updateStudy(uint256 studyId, string memory studyName, address supervisorId) public payable 
    {
        require(
            studies[studyId].studyId > 0 && studies[studyId].isDeleted == false,
            "Study does not exist or deleted"
        );
        require(
            studies[studyId].creatorId == msg.sender,
            "Study creator does not match the caller"
        );
        studies[studyId].studyName = studyName;
        studies[studyId].supervisorId = supervisorId;
    }
    
     
    function upsertStudy(uint256 studyId, string memory studyName, address supervisorId) public payable 
    {
        if (studies[studyId].studyId > 0) {
            updateStudy(studyId,studyName,supervisorId);
        } else {
            addStudy(studyId,studyName,supervisorId);
        }
    }
    
     
    function deleteStudy(uint256 studyId) public payable 
    {
        require(
            studies[studyId].studyId > 0 && studies[studyId].isDeleted == false,
            "Study does not exist or deleted"
        );
        require(
            studies[studyId].creatorId == msg.sender,
            "Study creator does not match the caller"
        );
        studies[studyId].isDeleted = true;
    }
    
     
    function addSurvey(string memory surveyName, uint256 studyId, uint256 surveyId, uint256 surveyJsonHash) public payable 
    {
        require(
            studies[studyId].studyId > 0 && studies[studyId].isDeleted == false,
            "Study does not exist or deleted"
        );
        require(
            studies[studyId].creatorId == msg.sender,
            "Study creator does not match the caller"
        );
        require(
            studies[studyId].surveys[surveyId].surveyId == 0,
            "Survey already exists or deleted"
        );
        Survey memory surveyObject = Survey(studyId, surveyId, surveyName, surveyJsonHash, false, new uint256[](0)); 
        studies[studyId].surveys[surveyId] = surveyObject;
        studies[studyId].surveyIds.push(surveyId);
    }
    
     
    function updateSurvey(string memory surveyName, uint256 studyId, uint256 surveyId, uint256 surveyJsonHash) public payable 
    {
        require(
            studies[studyId].studyId > 0 && studies[studyId].isDeleted == false,
            "Study does not exist or deleted"
        );
        require(
            studies[studyId].creatorId == msg.sender,
            "Study creator does not match the caller"
        );
        require(
            studies[studyId].surveys[surveyId].surveyId > 0 && studies[studyId].surveys[surveyId].isDeleted == false,
            "Survey does not exist or deleted"
        );
        Survey memory surveyObject = Survey(studyId, surveyId, surveyName, surveyJsonHash, false, new uint256[](0));
        studies[studyId].surveys[surveyId] = surveyObject;
    }
    
     
    function upsertSurvey(string memory surveyName, uint256 studyId, uint256 surveyId, uint256 surveyJsonHash) public payable 
    {
        if (studies[studyId].surveys[surveyId].surveyId > 0) {
            updateSurvey(surveyName,studyId,surveyId,surveyJsonHash);
        } else {
            addSurvey(surveyName,studyId,surveyId,surveyJsonHash);
        }
    }
    
     
    function deleteSurvey(uint256 studyId, uint256 surveyId) public payable 
    {
        require(
            studies[studyId].studyId > 0 && studies[studyId].isDeleted == false,
            "Study does not exist or deleted"
        );
        require(
            studies[studyId].creatorId == msg.sender,
            "Study creator does not match the caller"
        );
        require(
            studies[studyId].surveys[surveyId].surveyId > 0 && studies[studyId].surveys[surveyId].isDeleted == false,
            "Survey does not exist or deleted"
        );      
        studies[studyId].surveys[surveyId].isDeleted = true;
    }
    
       
    function addParticipantConsent(uint256 studyId, uint256 timestamp) public payable 
    {
        require(
            studies[studyId].studyId > 0 && studies[studyId].isDeleted == false,
            "Study does not exist or deleted"
        );
        require(
            studies[studyId].consents[msg.sender].signedByParticipantAt == 0,
            "Consent already done"
        );
        Consent memory studyconsent = Consent(timestamp, 0, 0);
        studies[studyId].consents[msg.sender] = studyconsent;
        studies[studyId].participants.push(msg.sender);
    }
    
       
    function notarizeParticipationAnswersHash(uint256 studyId, uint256 surveyId, uint256 answersJsonHash) public payable 
    {
        require(
            studies[studyId].studyId > 0 && studies[studyId].isDeleted == false,
            "Study does not exist or deleted"
        );
        require(
            studies[studyId].surveys[surveyId].surveyId > 0 && studies[studyId].surveys[surveyId].isDeleted == false,
            "Survey does not exist or deleted"
        );
        require(
            studies[studyId].consents[msg.sender].signedByParticipantAt > 0,
            "Consent not done yet"
        );
        studies[studyId].surveys[surveyId].answersJsonHash[msg.sender] = answersJsonHash;
    }
    
       
    function addStudyCreatorConsent(uint256 studyId, address participantId, uint256 timestamp) public payable 
    {
        require(
            studies[studyId].studyId > 0 && studies[studyId].isDeleted == false,
            "Study does not exist or deleted"
        );
        require(
            studies[studyId].creatorId == msg.sender,
            "Study creator does not match the caller"
        );
        require(
            studies[studyId].consents[participantId].signedByParticipantAt > 0,
            "Consent does not exist"
        );
        require(
            studies[studyId].consents[participantId].signedByStudyCreatorAt == 0,
            "Consent already signed"
        );
        studies[studyId].consents[participantId].signedByStudyCreatorAt = timestamp;
    }
    
       
    function addStudyCreatorConsentToUnsignedConsents(uint256 studyId, uint256 timestamp, uint256 limit) public payable 
    {
        require(
            studies[studyId].studyId > 0 && studies[studyId].isDeleted == false,
            "Study does not exist or deleted"
        );
        require(
            studies[studyId].creatorId == msg.sender,
            "Study creator does not match the caller"
        );
        for(uint i = 0; i < studies[studyId].participants.length; i++)
        {
            address participantId = studies[studyId].participants[i];
            if (studies[studyId].consents[participantId].signedByStudyCreatorAt == 0) 
            {
                studies[studyId].consents[participantId].signedByStudyCreatorAt = timestamp;
            }
            if (i>limit) break;
        }
    }
    
       
    function addStudySupervisorConsent(uint256 studyId, address participantId, uint256 timestamp) public payable 
    {
        require(
            studies[studyId].studyId > 0 && studies[studyId].isDeleted == false,
            "Study does not exist or deleted"
        );
        require(
            studies[studyId].supervisorId == msg.sender,
            "Study supervisor does not match the caller"
        );
        require(
            studies[studyId].consents[participantId].signedByParticipantAt > 0,
            "Consent does not exists"
        );
        require(
            studies[studyId].consents[participantId].signedByStudySupervisorAt == 0,
            "Consent already signed"
        );
        studies[studyId].consents[participantId].signedByStudySupervisorAt = timestamp;
    }
    
       
    function addStudySupervisorConsentToUnsignedConsents(uint256 studyId, uint256 timestamp, uint256 limit) public payable 
    {
        require(
            studies[studyId].studyId > 0 && studies[studyId].isDeleted == false,
            "Study does not exist or deleted"
        );
        require(
            studies[studyId].supervisorId == msg.sender,
            "Study supervisor does not match the caller"
        );
        for(uint i = 0; i < studies[studyId].participants.length; i++)
        {
            address participantId = studies[studyId].participants[i];
            if (studies[studyId].consents[participantId].signedByStudySupervisorAt == 0) 
            {
                studies[studyId].consents[participantId].signedByStudySupervisorAt = timestamp;
            }
            if (i>limit) break;
        }
    }
    
     
    function notarizeSurveyExport(uint256 studyId, uint256 surveyId, uint256 hashResult) public payable 
    {
        require(
            studies[studyId].studyId > 0 && studies[studyId].isDeleted == false,
            "Study does not exist or deleted"
        );
        require(
            studies[studyId].creatorId == msg.sender,
            "Study creator does not match the caller"
        );
         require(
            studies[studyId].surveys[surveyId].surveyId > 0 && studies[studyId].surveys[surveyId].isDeleted == false,
            "Survey does not exist or deleted"
        );
        studies[studyId].surveys[surveyId].exportedHash.push(hashResult);
    }
   
     
    function getStudies() public view returns (uint256[] memory)
    {
        return studiesIDs;
    }
    
     
    function getStudyInfos(uint256 studyId) public view returns (uint256, string memory, address, address, bool, uint256, uint256[] memory)
    {
        return (
            studies[studyId].studyId,
            studies[studyId].studyName,
            studies[studyId].creatorId,
            studies[studyId].supervisorId,
            studies[studyId].isDeleted,
            studies[studyId].participants.length,
            studies[studyId].surveyIds
        );
    }
    
     
    function getSurveyAnswersHash(uint256 studyId, uint256 surveyId, address participantId) public view returns (uint256)
    {
        return (
            studies[studyId].surveys[surveyId].answersJsonHash[participantId]
        );
    }
    
     
    function getStudyParticipants(uint256 studyId) public view returns (address[] memory)
    {
        return studies[studyId].participants;
    }
    
     
    function getStudyConsents(uint256 studyId) public view returns (uint256[] memory, uint256[] memory, uint256[] memory)
    {
        uint participantsCount = studies[studyId].participants.length;
        uint256[] memory signedByParticipantAt = new uint256[](participantsCount);
        uint256[] memory signedByStudyCreatorAt = new uint256[](participantsCount);
        uint256[] memory signedByStudySupervisorAt = new uint256[](participantsCount);
        
        for(uint i = 0; i < participantsCount; i++)
        {
            address participantId = studies[studyId].participants[i];
            signedByParticipantAt[i] = studies[studyId].consents[participantId].signedByParticipantAt;
            signedByStudyCreatorAt [i] = studies[studyId].consents[participantId].signedByStudyCreatorAt;
            signedByStudySupervisorAt[i] = studies[studyId].consents[participantId].signedByStudySupervisorAt;
        }
        return (
            signedByParticipantAt,
            signedByStudyCreatorAt,
            signedByStudySupervisorAt
        );
    }
    
     
    function getSurveyInfos(uint256 studyId, uint256 surveyId) public view returns (uint256, uint256, string memory, uint256, bool, uint256[] memory)
    {
        return (
            studies[studyId].surveys[surveyId].studyId,
            studies[studyId].surveys[surveyId].surveyId,
            studies[studyId].surveys[surveyId].surveyName,
            studies[studyId].surveys[surveyId].surveyJsonHash,
            studies[studyId].surveys[surveyId].isDeleted,
            studies[studyId].surveys[surveyId].exportedHash
        );
    }
    
}
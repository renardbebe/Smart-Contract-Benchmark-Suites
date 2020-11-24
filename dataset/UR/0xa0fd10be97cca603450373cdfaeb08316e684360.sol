 

contract DataService {
    event NewDataRequest(uint id, bool initialized, string dataUrl); 
    event GetDataRequestLength(uint length);
    event GetDataRequest(uint id, bool initialized, string dataurl, uint dataPointsLength);

    event AddDataPoint(uint dataRequestId, bool success, string response);
    event GetDataPoint(uint dataRequestId, uint id, bool success, string response);

    struct DataPoint {
        bool initialized;
        bool success;
        string response; 
    }
    struct DataRequest {
        bool initialized;
        string dataUrl;
        DataPoint[] dataPoints;
    }

    address private organizer;
    DataRequest[] private dataRequests;

     
    function DataService() {
        organizer = msg.sender;
    }
    
     
    function() {
        throw;
    }
    
     
    function addDataRequest(string dataUrl) {
         
        if(msg.sender != organizer) { throw; }

         
        uint nextIndex = dataRequests.length++;
    
         
        DataRequest newDataRequest = dataRequests[nextIndex];
        newDataRequest.initialized = true;
        newDataRequest.dataUrl = dataUrl;

        NewDataRequest(dataRequests.length - 1, newDataRequest.initialized, newDataRequest.dataUrl);
    }

     
    function getDataRequestLength() {
        GetDataRequestLength(dataRequests.length);
    }

     
    function getDataRequest(uint id) {
        DataRequest dataRequest = dataRequests[id];
        GetDataRequest(id, dataRequest.initialized, dataRequest.dataUrl, dataRequest.dataPoints.length);
    }

     
    function getDataPoint(uint dataRequestId, uint dataPointId) {
        DataRequest dataRequest = dataRequests[dataRequestId];
        DataPoint dataPoint = dataRequest.dataPoints[dataPointId];

        GetDataPoint(dataRequestId, dataPointId, dataPoint.success, dataPoint.response);
    }

     
    function addDataPoint(uint dataRequestId, bool success, string response) {
        if(msg.sender != organizer) { throw; }
        
         
        DataRequest dataRequest = dataRequests[dataRequestId];
        if(!dataRequest.initialized) { throw; }

         
        DataPoint newDataPoint = dataRequest.dataPoints[dataRequest.dataPoints.length++];
        newDataPoint.initialized = true;
        newDataPoint.success = success;
        newDataPoint.response = response;

        AddDataPoint(dataRequestId, success, response);
    }

     
    function destroy() {
        if(msg.sender != organizer) { throw; }
        
        suicide(organizer);
    }
}
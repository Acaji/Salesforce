/******************************************************//**
@class     VisualizeController.cls
@brief     Visualforce or Lightning Controller to populate initial
            and update state of lifeforms in Game of Life

@created    2014-11-14  Janeen Anderson 

This class is without sharing because it presents 
it is a cinematic view available to all users.

Copyright Janeen Anderson Nov 11, 2014
**********************************************************/
global without sharing class VisualizeController {
    /******************************************************
    @paramete6 List<String> neighborsList 
    @brief  list all of the lifeform neighbor fieldnames ( direction they represent ) 
    ******************************************************/
        //                  N (2)
        //          NW (3)  ^   NE (1)
        //                \ | /
        //        W (4) < -- --> E (0)
        //                / | \
        //          SW (5)      SE (7)
        //                  S (6)
    static public List<String> neighborsList {
        get{
            if (neighborsList == null) {
                neighborsList = new List<String> {
                    'Neighbor_East__r',
                    'Neighbor_NE__r',
                    'Neighbor_North__r',
                    'Neighbor_NW__r',
                    'Neighbor_West__r',
                    'Neighbor_SW__r',
                    'Neighbor_South__r',
                    'Neighbor_SE__r'};
            }
            return neighborsList;
        }
    }
    
    /******************************************************
    @constructor
    @brief      does nothing (and why am I here?)
    
    @return VisualizeController.cls
    ******************************************************/ 
    public VisualizeController() {}
    
    public String GetLifeforms () {
        Map<Integer, LifeformElement> visualEcosystem = new Map<Integer, LifeformElement>();
        List<LifeForm__c> ecosystem = new List<LifeForm__c>([
            SELECT Index__c, Alive__c, X_Coordinate__c, Y_Coordinate__c, 
                    Neighbor_East__c, Neighbor_West__c, Neighbor_South__c, Neighbor_North__c,
                    Neighbor_NE__c, Neighbor_NW__c, Neighbor_SE__c, Neighbor_SW__c,
                    Neighbor_East__r.Index__c, Neighbor_West__r.Index__c, Neighbor_South__r.Index__c, Neighbor_North__r.Index__c,
                    Neighbor_NE__r.Index__c, Neighbor_NW__r.Index__c, Neighbor_SE__r.Index__c, Neighbor_SW__r.Index__c,
                    Neighbor_East__r.Alive__c, Neighbor_West__r.Alive__c, Neighbor_South__r.Alive__c, Neighbor_North__r.Alive__c,
                    Neighbor_NE__r.Alive__c, Neighbor_NW__r.Alive__c, Neighbor_SE__r.Alive__c, Neighbor_SW__r.Alive__c,
                    Neighbor_East__r.X_Coordinate__c, Neighbor_West__r.X_Coordinate__c, Neighbor_South__r.X_Coordinate__c, Neighbor_North__r.X_Coordinate__c,
                    Neighbor_NE__r.X_Coordinate__c, Neighbor_NW__r.X_Coordinate__c, Neighbor_SE__r.X_Coordinate__c, Neighbor_SW__r.X_Coordinate__c,
                    Neighbor_East__r.Y_Coordinate__c, Neighbor_West__r.Y_Coordinate__c, Neighbor_South__r.Y_Coordinate__c, Neighbor_North__r.Y_Coordinate__c,
                    Neighbor_NE__r.Y_Coordinate__c, Neighbor_NW__r.Y_Coordinate__c, Neighbor_SE__r.Y_Coordinate__c, Neighbor_SW__r.Y_Coordinate__c                        
            FROM LifeForm__c
            ORDER BY Index__c ASC]);
        for (LifeForm__c theCreature : ecosystem ){
            visualEcosystem.put((Integer)theCreature.Index__c, new LifeformElement(theCreature, neighborsList));
        }
        return json.serialize( visualEcosystem );
    }
    
    static Integer countLiveNeighbors( LifeForm__c life ){
        Integer theCount = 0;
        if (life.Neighbor_East__r.Alive__c) theCount++;
        if (life.Neighbor_West__r.Alive__c) theCount++;
        if (life.Neighbor_South__r.Alive__c) theCount++;
        if (life.Neighbor_North__r.Alive__c) theCount++;
        if (life.Neighbor_NE__r.Alive__c) theCount++;
        if (life.Neighbor_NW__r.Alive__c) theCount++;
        if (life.Neighbor_SE__r.Alive__c) theCount++;
        if (life.Neighbor_SW__r.Alive__c) theCount++;
        return theCount;
    }
    
    private class Position {
        Integer  x;
        Integer  y;
        
        public Position() {}
        public Position(LifeForm__c aLife) 
        { 
            if(aLife == null) return;
            x = Integer.valueOf(aLife.X_Coordinate__c); 
            y = Integer.valueOf(aLife.Y_Coordinate__c);
        }
    }
    
    public class LifeformElement{
        public Position         me;
        public List<Position>   Neighbors;
        public List<Integer>    NeighborIndx;
        public Boolean          alive;
        public Boolean          nextState;
        private Integer         liveCount;

        private void setNeighborIndicesAncCountTheLiving(LifeForm__c life, List<String> neighborsList) {
            List<Integer> rval = new List<Integer>();
            NeighborIndx = new List<Integer>{null,null,null,null,null,null,null,null};
            liveCount = 0;
            Integer indexoffset = 4;        // pair with neighbor, east to west, etd
            integer numDirections = 8;
            Integer index = 0;

            for (String neighborFieldName : neighborsList) {
                LifeForm__c neighborLifeform = (LifeForm__c)life.getSObject(neighborFieldName);
                Neighbors.add( new Position(neighborLifeform) );
                Integer LifeformIndexOfNeighbor = (neighborLifeform == null || neighborLifeform.get('Index__c') == null) ? 
                    null : Integer.valueOf(neighborLifeform.get('Index__c'));
                NeighborIndx[Math.mod(index + indexoffset, numDirections)] = LifeformIndexOfNeighbor;
                if (LifeformIndexOfNeighbor != null && neighborLifeform.get('Alive__c') == true) liveCount++;
                index++;
            }   
        }
        
        public LifeformElement(LifeForm__c life, List<String> neighborsList) {
            me = new Position(life);
            alive = life.Alive__c;
            Neighbors = new List<Position>();
            setNeighborIndicesAncCountTheLiving(life, neighborsList);

            nextState = alive;
            if(alive && liveCount !=2 && liveCount != 3) nextState = false;
            if(!alive && liveCount == 3) nextState = true;
        }
    }
}
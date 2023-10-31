package com.java.app;

import java.util.Map;
import java.util.Properties;
import java.util.TreeMap;

public class ReadEnvtVars {
    public static void main(){

        System.out.println("ENVT PROPERTIES");
        System.out.println("===============");
        printAllEnvt(true);

        System.out.println("\n\nSYSTEM PROPERTIES");
        System.out.println("===============");
        printAllSystemProperties(true);

    }

    private static void printAllEnvt(boolean sorted){
        Map<String,String> envt = System.getenv();

        if(sorted){
            envt = new TreeMap<>(envt);
        }

        int i = 1;
        for(Map.Entry<String,String> val : envt.entrySet()){
            System.out.println((i++)+". "+val.getKey()+" <=> "+val.getValue());
        }
    }

    private static void printAllSystemProperties(boolean sorted){
        Map properties = System.getProperties();

        if(sorted){
            properties = new TreeMap<>(properties);
        }

        int[] countArr = {1};        
        properties.forEach((k,v) -> System.out.println((countArr[0]++)+". "+k+"="+v));
        

        
    }

}

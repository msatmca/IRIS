/*
 * generated by Xtext
 */
package com.temenos.interaction.rimdsl.generator

import org.eclipse.emf.ecore.resource.Resource
import org.eclipse.xtext.generator.IGenerator
import org.eclipse.xtext.generator.IFileSystemAccess
import com.temenos.interaction.rimdsl.rim.Command
import com.temenos.interaction.rimdsl.rim.State
import com.temenos.interaction.rimdsl.rim.Transition
import com.temenos.interaction.rimdsl.rim.TransitionForEach
import com.temenos.interaction.rimdsl.rim.TransitionAuto
import com.temenos.interaction.rimdsl.rim.ResourceInteractionModel
import org.eclipse.emf.common.util.EList
import com.temenos.interaction.rimdsl.rim.UriLink
import com.temenos.interaction.rimdsl.rim.UriLinkageEntityKeyReplace

class RIMDslGenerator implements IGenerator {
	
	override void doGenerate(Resource resource, IFileSystemAccess fsa) {
		fsa.generateFile(resource.className+"Behaviour.java", toJavaCode(resource.contents.head as ResourceInteractionModel))
	}
	
	def className(Resource res) {
		var name = res.URI.lastSegment
		return name.substring(0, name.indexOf('.'))
	}
	
	def toJavaCode(ResourceInteractionModel rim) '''
		import java.util.HashSet;
		import java.util.Set;
		import java.util.HashMap;
		import java.util.Map;
		import java.util.Properties;

		import com.temenos.interaction.core.hypermedia.UriSpecification;
		import com.temenos.interaction.core.hypermedia.Action;
		import com.temenos.interaction.core.hypermedia.CollectionResourceState;
		import com.temenos.interaction.core.hypermedia.ResourceState;
		import com.temenos.interaction.core.hypermedia.ResourceStateMachine;
		import com.temenos.interaction.core.hypermedia.validation.HypermediaValidator;
		
		public class «rim.eResource.className»Behaviour {
		
		    public static void main(String[] args) {
		        ResourceStateMachine hypermediaEngine = new ResourceStateMachine(new «rim.eResource.className»Behaviour().getRIM());
		        HypermediaValidator validator = HypermediaValidator.createValidator(hypermediaEngine);
		        System.out.println(validator.graph());
		    }
		
			public ResourceState getRIM() {
				Map<String, String> uriLinkageEntityProperties = new HashMap<String, String>();
				Map<String, String> uriLinkageProperties = new HashMap<String, String>();
				Properties actionViewProperties = new Properties();
				ResourceState initial = null;
				// create states
				«FOR c : rim.states»
					«c.produceResourceStates»
					«IF c.isInitial»
					// identify the initial state
					initial = s«c.name»;
					«ENDIF»
				«ENDFOR»

				// create regular transitions
				«FOR c : rim.states»
					«FOR t : c.transitions»
						«produceTransitions(c, t)»
					«ENDFOR»
				«ENDFOR»

		        // create foreach transitions
                «FOR c : rim.states»
                    «FOR t : c.transitionsForEach»
                        «produceTransitionsForEach(c, t)»
                    «ENDFOR»
                «ENDFOR»

		        // create AUTO transitions
                «FOR c : rim.states»
                    «FOR t : c.transitionsAuto»
                        «produceTransitionsAuto(c, t)»
                    «ENDFOR»
                «ENDFOR»

			    return initial;
			}

		    private Set<Action> createActionSet(Action view, Action entry) {
		        Set<Action> actions = new HashSet<Action>();
		        if (view != null)
		            actions.add(view);
		        if (entry != null)
		            actions.add(entry);
		        return actions;
		    }

		}
	'''
	
	def produceResourceStates(State state) '''
            «IF state.actions != null && state.actions.size > 0»
                «FOR commandProperty : state.actions.get(0).property»
                actionViewProperties.put("«commandProperty.name»", "«commandProperty.value»");«
                ENDFOR»
            «ENDIF»
            «IF state.entity.isCollection»
            CollectionResourceState s«state.name» = new CollectionResourceState("«state.entity.name»", "«state.name»", «produceActionSet(state.actions)», "«if (state.path != null) { state.path.name }»");
            «ELSEIF state.entity.isItem»
            ResourceState s«state.name» = new ResourceState("«state.entity.name»", "«state.name»", «produceActionSet(state.actions)», "«if (state.path != null) { state.path.name }»"«if (state.path != null) { ", new UriSpecification(\"" + state.name + "\", \"" + state.path.name + "\")" }»);
            «ENDIF»
	'''

    def produceActionSet(EList<Command> actions) '''
        «IF actions != null»
            «IF actions.size == 2»
            createActionSet(new Action("«actions.get(0).name»", Action.TYPE.VIEW, actionViewProperties), new Action("«actions.get(1).name»", Action.TYPE.ENTRY))«
            ELSEIF actions.size == 1»
            createActionSet(new Action("«actions.get(0).name»", Action.TYPE.VIEW, actionViewProperties), null)«
            ENDIF»«
        ENDIF»'''
    
	def produceTransitions(State fromState, Transition transition) '''
			«produceUriLinkage(transition.uriLinks)»
			s«fromState.name».addTransition("«transition.event.name»", s«transition.state.name», uriLinkageEntityProperties, uriLinkageProperties);
	'''

    def produceTransitionsForEach(State fromState, TransitionForEach transition) '''
            «produceUriLinkage(transition.uriLinks)»
            s«fromState.name».addTransitionForEachItem("«transition.event.name»", s«transition.state.name», uriLinkageEntityProperties, uriLinkageProperties);
    '''
		
    def produceTransitionsAuto(State fromState, TransitionAuto transition) '''
            s«fromState.name».addTransition(s«transition.state.name»);
    '''

    def produceUriLinkage(EList<UriLink> uriLinks) '''
        «IF uriLinks != null»
            «FOR prop : uriLinks»
            «IF prop.entityProperty instanceof UriLinkageEntityKeyReplace»
            uriLinkageEntityProperties.put("«prop.templateProperty»", "«prop.entityProperty.name»");
            «ELSE»
            uriLinkageProperties.put("«prop.templateProperty»", "«prop.entityProperty.name»");
            «ENDIF»
            «ENDFOR»«
        ENDIF»
    '''

}

